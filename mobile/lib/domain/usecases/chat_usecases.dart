import 'dart:io';

import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';
import 'package:smartlife_app/domain/repositories/chat_repository.dart';

class ChatUseCases {
  ChatUseCases(this._repository);

  final ChatRepository _repository;

  Future<List<ChatConversationEntity>> getConversations() =>
      _repository.getConversations();
  Future<List<ChatConversationEntity>> searchUsers(String keyword) =>
      _repository.searchUsers(keyword);
  Future<List<ChatMessageEntity>> getMessages(String chatId) =>
      _repository.getMessages(chatId);
  Future<ChatMessageEntity> sendMessage({
    required String text,
    String? receiverId,
    String? chatId,
    String type = 'text',
    String? attachmentUrl,
  }) {
    return _repository.sendMessage(
      text: text,
      receiverId: receiverId,
      chatId: chatId,
      type: type,
      attachmentUrl: attachmentUrl,
    );
  }

  Future<String> uploadFile(File file) => _repository.uploadFile(file);

  Future<void> deleteMessage(String id) => _repository.deleteMessage(id);

  Future<void> deleteConversation(String id) =>
      _repository.deleteConversation(id);

  void connectSocket(String token) => _repository.connectSocket(token);
  void disconnectSocket() => _repository.disconnectSocket();
  void emitTyping({required String toUserId, required bool isTyping}) =>
      _repository.emitTyping(toUserId: toUserId, isTyping: isTyping);

  Stream<ChatMessageEntity> onNewMessage() => _repository.onNewMessage();
  Stream<Map<String, dynamic>> onTyping() => _repository.onTyping();
  Stream<Map<String, dynamic>> onPresence() => _repository.onPresence();
  Stream<Map<String, dynamic>> onRead() => _repository.onRead();
}
