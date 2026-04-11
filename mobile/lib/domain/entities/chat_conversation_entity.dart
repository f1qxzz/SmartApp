class ChatConversationEntity {
  final String contactId;
  final String name;
  final String email;
  final String avatar;
  final bool isOnline;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;

  const ChatConversationEntity({
    required this.contactId,
    required this.name,
    required this.email,
    required this.avatar,
    required this.isOnline,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
  });

  factory ChatConversationEntity.fromJson(Map<String, dynamic> json) {
    final contact = Map<String, dynamic>.from(json['contact'] as Map? ?? {});

    return ChatConversationEntity(
      contactId: (contact['id'] ?? contact['_id'] ?? '').toString(),
      name: (contact['name'] ?? '').toString(),
      email: (contact['email'] ?? '').toString(),
      avatar: (contact['avatar'] ?? '').toString(),
      isOnline: (contact['isOnline'] ?? false) == true,
      lastMessage: (json['lastMessage'] ?? '').toString(),
      lastTimestamp: DateTime.tryParse((json['lastTimestamp'] ?? '').toString()) ?? DateTime.now(),
      unreadCount: (json['unreadCount'] ?? 0) as int,
    );
  }
}
