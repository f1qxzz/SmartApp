class ChatMessageEntity {
  final String id;
  final String chatId;
  final String senderId;
  final String senderUsername;
  final String senderAvatar;
  final String text;
  final String type;
  final String attachmentUrl;
  final DateTime createdAt;
  final Map<String, String>? reactions;
  final String? replyToId;
  final ChatMessageEntity? replyToMessage;

  const ChatMessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderUsername,
    required this.senderAvatar,
    required this.text,
    this.type = 'text',
    this.attachmentUrl = '',
    required this.createdAt,
    this.reactions,
    this.replyToId,
    this.replyToMessage,
  });

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    final senderRaw = json['senderId'];
    final sender = senderRaw is Map<String, dynamic>
        ? senderRaw
        : senderRaw is Map
            ? Map<String, dynamic>.from(senderRaw)
            : <String, dynamic>{'_id': senderRaw};

    final String createdAtRaw =
        (json['createdAt'] ?? json['timestamp'] ?? '').toString();
    final DateTime parsedCreatedAt =
        DateTime.tryParse(createdAtRaw)?.toLocal() ?? DateTime.now();

    // Parse reactions
    Map<String, String>? reactions;
    if (json['reactions'] != null && json['reactions'] is Map) {
      reactions = Map<String, String>.from(json['reactions']);
    }

    // Parse replyToMessage
    ChatMessageEntity? replyToMessage;
    if (json['replyToMessage'] != null && json['replyToMessage'] is Map) {
      replyToMessage = ChatMessageEntity.fromJson(
        Map<String, dynamic>.from(json['replyToMessage']),
      );
    }

    return ChatMessageEntity(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      chatId: (json['chatId'] ?? '').toString(),
      senderId: (sender['_id'] ?? sender['id'] ?? '').toString(),
      senderUsername: (sender['username'] ?? sender['name'] ?? '').toString(),
      senderAvatar: (sender['avatar'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      type: (json['messageType'] ?? json['type'] ?? 'text').toString(),
      attachmentUrl: (json['attachmentUrl'] ?? '').toString(),
      createdAt: parsedCreatedAt,
      reactions: reactions,
      replyToId: json['replyToId']?.toString(),
      replyToMessage: replyToMessage,
    );
  }

  ChatMessageEntity copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderUsername,
    String? senderAvatar,
    String? text,
    String? type,
    String? attachmentUrl,
    DateTime? createdAt,
    Map<String, String>? reactions,
    String? replyToId,
    ChatMessageEntity? replyToMessage,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      text: text ?? this.text,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
    );
  }
}
