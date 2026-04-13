import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

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
  }) async {
    try {
      final response = await _dioClient.instance.post(
        '/messages/send',
        data: {
          'text': text,
          if (receiverId != null && receiverId.trim().isNotEmpty)
            'receiverId': receiverId,
          if (chatId != null && chatId.trim().isNotEmpty) 'chatId': chatId,
        },
      );

      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return ChatMessageEntity.fromJson(data);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> uploadImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final response =
          await _dioClient.instance.post('/api/upload', data: formData);
      final path = (response.data['data']['url'] ?? '').toString();
      return UrlHelper.toAbsolute(EnvConfig.apiBaseUrl, path);
    } catch (error) {
      throw ApiException.fromDio(error);
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
}
