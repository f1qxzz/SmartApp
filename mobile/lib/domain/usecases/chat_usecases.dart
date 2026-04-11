import 'dart:io';

import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';
import 'package:smartlife_app/domain/repositories/chat_repository.dart';

class ChatUseCases {
  ChatUseCases(this._repository);

  final ChatRepository _repository;

  Future<List<ChatConversationEntity>> getConversations() => _repository.getConversations();
  Future<List<ChatConversationEntity>> getContacts() => _repository.getContacts();
  Future<List<ChatMessageEntity>> getMessages(String contactId) => _repository.getMessages(contactId);
  Future<ChatMessageEntity> sendMessage({required String receiverId, String text = '', String image = ''}) {
    return _repository.sendMessage(receiverId: receiverId, text: text, image: image);
  }

  Future<void> markAsRead(String contactId) => _repository.markAsRead(contactId);
  Future<String> uploadImage(File file) => _repository.uploadImage(file);

  void connectSocket(String token) => _repository.connectSocket(token);
  void disconnectSocket() => _repository.disconnectSocket();
  void emitTyping({required String toUserId, required bool isTyping}) => _repository.emitTyping(toUserId: toUserId, isTyping: isTyping);

  Stream<ChatMessageEntity> onNewMessage() => _repository.onNewMessage();
  Stream<Map<String, dynamic>> onTyping() => _repository.onTyping();
  Stream<Map<String, dynamic>> onPresence() => _repository.onPresence();
  Stream<Map<String, dynamic>> onRead() => _repository.onRead();
}
