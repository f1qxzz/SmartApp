import 'dart:io';

import 'package:smartlife_app/data/services/chat_service.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';
import 'package:smartlife_app/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._chatService);

  final ChatService _chatService;

  @override
  Future<List<ChatConversationEntity>> getConversations() => _chatService.getConversations();

  @override
  Future<List<ChatConversationEntity>> getContacts() => _chatService.getContacts();

  @override
  Future<List<ChatMessageEntity>> getMessages(String contactId) => _chatService.getMessages(contactId);

  @override
  Future<ChatMessageEntity> sendMessage({required String receiverId, String text = '', String image = ''}) {
    return _chatService.sendMessage(receiverId: receiverId, text: text, image: image);
  }

  @override
  Future<void> markAsRead(String contactId) => _chatService.markAsRead(contactId);

  @override
  Future<String> uploadImage(File file) => _chatService.uploadImage(file);

  @override
  void connectSocket(String token) => _chatService.connectSocket(token);

  @override
  void disconnectSocket() => _chatService.disconnectSocket();

  @override
  void emitTyping({required String toUserId, required bool isTyping}) {
    _chatService.emitTyping(toUserId: toUserId, isTyping: isTyping);
  }

  @override
  Stream<ChatMessageEntity> onNewMessage() => _chatService.onNewMessage();

  @override
  Stream<Map<String, dynamic>> onTyping() => _chatService.onTyping();

  @override
  Stream<Map<String, dynamic>> onPresence() => _chatService.onPresence();

  @override
  Stream<Map<String, dynamic>> onRead() => _chatService.onRead();
}
