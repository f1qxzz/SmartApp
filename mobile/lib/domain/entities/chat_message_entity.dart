class ChatMessageEntity {
  final String id;
  final String chatId;
  final String senderId;
  final String senderUsername;
  final String senderAvatar;
  final String text;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderUsername,
    required this.senderAvatar,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    final senderRaw = json['senderId'];
    final sender = senderRaw is Map<String, dynamic>
        ? senderRaw
        : senderRaw is Map
            ? Map<String, dynamic>.from(senderRaw)
            : <String, dynamic>{'_id': senderRaw};

    return ChatMessageEntity(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      chatId: (json['chatId'] ?? '').toString(),
      senderId: (sender['_id'] ?? sender['id'] ?? '').toString(),
      senderUsername: (sender['username'] ?? sender['name'] ?? '').toString(),
      senderAvatar: (sender['avatar'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? json['timestamp'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  ChatMessageEntity copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderUsername,
    String? senderAvatar,
    String? text,
    DateTime? createdAt,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
