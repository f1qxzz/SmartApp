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
      final response = await _dioClient.instance.get('/api/chat');
      final rawList = (response.data['data'] as List?) ?? <dynamic>[];
      final data = rawList
          .map((item) => ChatConversationEntity.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      return data;
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<ChatConversationEntity>> getContacts() async {
    try {
      final response = await _dioClient.instance.get('/api/chat/users');
      final rawList = (response.data['data'] as List?) ?? <dynamic>[];

      return rawList.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return ChatConversationEntity(
          contactId: (map['_id'] ?? map['id'] ?? '').toString(),
          name: (map['name'] ?? '').toString(),
          email: (map['email'] ?? '').toString(),
          avatar: (map['avatar'] ?? '').toString(),
          isOnline: map['isOnline'] == true,
          lastMessage: '',
          lastTimestamp: DateTime.fromMillisecondsSinceEpoch(0),
          unreadCount: 0,
        );
      }).toList();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<ChatMessageEntity>> getMessages(String contactId) async {
    try {
      final response = await _dioClient.instance.get('/api/chat', queryParameters: {'with': contactId});
      final rawList = (response.data['data'] as List?) ?? <dynamic>[];

      return rawList
          .map((item) => _parseMessage(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChatMessageEntity> sendMessage({
    required String receiverId,
    String text = '',
    String image = '',
  }) async {
    try {
      final response = await _dioClient.instance.post('/api/chat', data: {
        'receiverId': receiverId,
        'text': text,
        'image': image,
      });

      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return _parseMessage(data);
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> markAsRead(String contactId) async {
    try {
      await _dioClient.instance.patch('/api/chat/read/$contactId');
    } catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> uploadImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final response = await _dioClient.instance.post('/api/upload', data: formData);
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
    _socketClient.emit('chat:typing', {
      'toUserId': toUserId,
      'isTyping': isTyping,
    });
  }

  Stream<ChatMessageEntity> onNewMessage() {
    _newMessageStream ??= _socketClient.on('chat:new').map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return _parseMessage(map);
    }).asBroadcastStream();

    return _newMessageStream!;
  }

  Stream<Map<String, dynamic>> onTyping() {
    _typingStream ??= _socketClient
        .on('chat:typing')
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

  ChatMessageEntity _parseMessage(Map<String, dynamic> map) {
    final parsed = ChatMessageEntity.fromJson(map);
    final normalizedImage = UrlHelper.toAbsolute(EnvConfig.apiBaseUrl, parsed.image);
    return parsed.copyWith(image: normalizedImage);
  }
}
