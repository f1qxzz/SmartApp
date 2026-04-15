import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:smartlife_app/core/config/env_config.dart';
import 'package:smartlife_app/core/network/api_exception.dart';
import 'package:smartlife_app/core/network/dio_client.dart';
import 'package:smartlife_app/core/network/socket_client.dart';
import 'package:smartlife_app/core/utils/url_helper.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';

class ChatService {
  ChatService(this._dioClient, this._socketClient);

  final DioClient _dioClient;
  final SocketClient _socketClient;

  Stream<ChatMessageEntity>? _newMessageStream;
  Stream<Map<String, dynamic>>? _typingStream;
  Stream<Map<String, dynamic>>? _presenceStream;
  Stream<Map<String, dynamic>>? _readStream;
  Stream<Map<String, dynamic>>? _reactionStream;

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }

    throw const ApiException('Format response API tidak valid');
  }

  Future<List<ChatConversationEntity>> getConversations() async {
    try {
      final response = await _dioClient.instance.get('/chats');
      final rawList = (response.data['data'] as List?) ?? <dynamic>[];
      return rawList
          .map((item) => ChatConversationEntity.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<ChatConversationEntity>> searchUsers(String keyword) async {
    try {
      final response = await _dioClient.instance.get(
        '/users/search',
        queryParameters: {
          'username': keyword.trim(),
        },
      );

      final rawList = (response.data['data'] as List?) ?? <dynamic>[];
      return rawList
          .map((item) => ChatConversationEntity.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<ChatMessageEntity>> getMessages(String chatId) async {
    try {
      final response = await _dioClient.instance.get('/messages/$chatId');
      final rawList = (response.data['data'] as List?) ?? <dynamic>[];

      return rawList
          .map(
            (item) => ChatMessageEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChatMessageEntity> sendMessage({
    required String text,
    String? receiverId,
    String? chatId,
    String type = 'text',
    String? attachmentUrl,
    String? replyToId,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        '/messages/send',
        data: {
          'text': text,
          'messageType': type,
          if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
          if (receiverId != null && receiverId.trim().isNotEmpty)
            'receiverId': receiverId,
          if (chatId != null && chatId.trim().isNotEmpty) 'chatId': chatId,
          if (replyToId != null && replyToId.trim().isNotEmpty)
            'replyToId': replyToId,
        },
      );

      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return ChatMessageEntity.fromJson(data);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> uploadFile(File file) async {
    try {
      final fileName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'upload_${DateTime.now().millisecondsSinceEpoch}';

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dioClient.instance.post(
        '/api/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );

      final root = _asMap(response.data);
      final payload = root['data'] is Map ? _asMap(root['data']) : root;
      final path = (payload['url'] ?? '').toString().trim();
      if (path.isEmpty) {
        throw const ApiException('URL file tidak ditemukan dari server');
      }
      return UrlHelper.toAbsolute(EnvConfig.apiBaseUrl, path);
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _dioClient.instance.delete('/messages/$messageId');
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteConversation(String chatId) async {
    try {
      await _dioClient.instance.delete('/conversations/$chatId');
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  }) async {
    // Emit socket event for real-time
    _socketClient.emit('chat:reaction', {
      'chatId': chatId,
      'messageId': messageId,
      'emoji': emoji,
    });

    // Optional: Call REST for persistence
    try {
      await _dioClient.instance.post(
        '/messages/reaction',
        data: {
          'chatId': chatId,
          'messageId': messageId,
          'emoji': emoji,
        },
      );
    } catch (error) {
      debugPrint('[CHAT] Add reaction REST failed: $error');
    }
  }

  void connectSocket(String token) {
    _socketClient.connect(token: token);
  }

  void disconnectSocket() {
    _socketClient.disconnect();
    _newMessageStream = null;
    _typingStream = null;
    _presenceStream = null;
    _readStream = null;
    _reactionStream = null;
  }

  void emitTyping({required String toUserId, required bool isTyping}) {
    _socketClient.emit('typing', {
      'toUserId': toUserId,
      'isTyping': isTyping,
    });
  }

  Stream<ChatMessageEntity> onNewMessage() {
    _newMessageStream ??= _socketClient.on('receive_message').map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return ChatMessageEntity.fromJson(map);
    }).asBroadcastStream();

    return _newMessageStream!;
  }

  Stream<Map<String, dynamic>> onTyping() {
    _typingStream ??= _socketClient
        .on('typing_status')
        .map((event) => Map<String, dynamic>.from(event as Map))
        .asBroadcastStream();

    return _typingStream!;
  }

  Stream<Map<String, dynamic>> onPresence() {
    _presenceStream ??= _socketClient
        .on('presence:update')
        .map((event) => Map<String, dynamic>.from(event as Map))
        .asBroadcastStream();

    return _presenceStream!;
  }

  Stream<Map<String, dynamic>> onRead() {
    _readStream ??= _socketClient
        .on('chat:read')
        .map((event) => Map<String, dynamic>.from(event as Map))
        .asBroadcastStream();

    return _readStream!;
  }

  Stream<Map<String, dynamic>> onReaction() {
    _reactionStream ??= _socketClient
        .on('chat:reaction')
        .map((event) => Map<String, dynamic>.from(event as Map))
        .asBroadcastStream();

    return _reactionStream!;
  }
}
