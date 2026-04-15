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
    String? replyToId,
  }) {
    return _repository.sendMessage(
      text: text,
      receiverId: receiverId,
      chatId: chatId,
      type: type,
      attachmentUrl: attachmentUrl,
      replyToId: replyToId,
    );
  }

  Future<String> uploadFile(File file) => _repository.uploadFile(file);

  Future<void> deleteMessage(String id) => _repository.deleteMessage(id);

  Future<void> deleteConversation(String id) =>
      _repository.deleteConversation(id);

  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  }) =>
      _repository.addReaction(
        chatId: chatId,
        messageId: messageId,
        emoji: emoji,
      );

  void connectSocket(String token) => _repository.connectSocket(token);
  void disconnectSocket() => _repository.disconnectSocket();
  void emitTyping({required String toUserId, required bool isTyping}) =>
      _repository.emitTyping(toUserId: toUserId, isTyping: isTyping);

  Stream<ChatMessageEntity> onNewMessage() => _repository.onNewMessage();
  Stream<Map<String, dynamic>> onTyping() => _repository.onTyping();
  Stream<Map<String, dynamic>> onPresence() => _repository.onPresence();
  Stream<Map<String, dynamic>> onRead() => _repository.onRead();
  Stream<Map<String, dynamic>> onReaction() => _repository.onReaction();
}
