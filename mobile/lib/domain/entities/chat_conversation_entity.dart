class ChatConversationEntity {
  final String chatId;
  final String userId;
  final String username;
  final String avatar;
  final bool isOnline;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  const ChatConversationEntity({
    required this.chatId,
    required this.userId,
    required this.username,
    required this.avatar,
    required this.isOnline,
    required this.lastMessage,
    required this.updatedAt,
    required this.unreadCount,
  });

  bool get hasChat => chatId.trim().isNotEmpty;

  factory ChatConversationEntity.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> userMap = Map<String, dynamic>.from(
      json['otherUser'] as Map? ?? json,
    );

    return ChatConversationEntity(
      chatId: (json['chatId'] ?? '').toString(),
      userId: (userMap['id'] ?? userMap['_id'] ?? '').toString(),
      username: (userMap['username'] ?? userMap['name'] ?? '').toString(),
      avatar: (userMap['avatar'] ?? '').toString(),
      isOnline: userMap['isOnline'] == true,
      lastMessage: (json['lastMessage'] ?? '').toString(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  ChatConversationEntity copyWith({
    String? chatId,
    String? userId,
    String? username,
    String? avatar,
    bool? isOnline,
    String? lastMessage,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return ChatConversationEntity(
      chatId: chatId ?? this.chatId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
