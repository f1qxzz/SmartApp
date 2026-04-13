import 'dart:io';

import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';

abstract class ChatRepository {
  Future<List<ChatConversationEntity>> getConversations();
  Future<List<ChatConversationEntity>> searchUsers(String keyword);
  Future<List<ChatMessageEntity>> getMessages(String chatId);
  Future<ChatMessageEntity> sendMessage({
    required String text,
    String? receiverId,
    String? chatId,
  });
  Future<String> uploadImage(File file);

  void connectSocket(String token);
  void disconnectSocket();
  void emitTyping({required String toUserId, required bool isTyping});

  Stream<ChatMessageEntity> onNewMessage();
  Stream<Map<String, dynamic>> onTyping();
  Stream<Map<String, dynamic>> onPresence();
  Stream<Map<String, dynamic>> onRead();
}
