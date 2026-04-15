import 'dart:io';

import 'package:smartlife_app/data/services/chat_service.dart';
import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';
import 'package:smartlife_app/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._chatService);

  final ChatService _chatService;

  @override
  Future<List<ChatConversationEntity>> getConversations() =>
      _chatService.getConversations();

  @override
  Future<List<ChatConversationEntity>> searchUsers(String keyword) =>
      _chatService.searchUsers(keyword);

  @override
  Future<List<ChatMessageEntity>> getMessages(String chatId) =>
      _chatService.getMessages(chatId);

  @override
  Future<ChatMessageEntity> sendMessage({
    required String text,
    String? receiverId,
    String? chatId,
    String type = 'text',
    String? attachmentUrl,
    String? replyToId,
  }) {
    return _chatService.sendMessage(
      text: text,
      receiverId: receiverId,
      chatId: chatId,
      type: type,
      attachmentUrl: attachmentUrl,
      replyToId: replyToId,
    );
  }

  @override
  Future<String> uploadFile(File file) => _chatService.uploadFile(file);

  @override
  Future<void> deleteMessage(String id) => _chatService.deleteMessage(id);

  @override
  Future<void> deleteConversation(String id) =>
      _chatService.deleteConversation(id);

  @override
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String emoji,
  }) {
    return _chatService.addReaction(
      chatId: chatId,
      messageId: messageId,
      emoji: emoji,
    );
  }

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

  @override
  Stream<Map<String, dynamic>> onReaction() => _chatService.onReaction();
}
