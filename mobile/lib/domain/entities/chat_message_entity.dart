class ChatMessageEntity {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String image;
  final DateTime timestamp;
  final bool readStatus;

  const ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.image,
    required this.timestamp,
    required this.readStatus,
  });

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    String _extractId(dynamic value) {
      if (value is Map<String, dynamic>) {
        return (value['_id'] ?? value['id'] ?? '').toString();
      }
      return (value ?? '').toString();
    }

    return ChatMessageEntity(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      senderId: _extractId(json['senderId']),
      receiverId: _extractId(json['receiverId']),
      text: (json['text'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      readStatus: (json['readStatus'] ?? false) == true,
    );
  }

  ChatMessageEntity copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    String? image,
    DateTime? timestamp,
    bool? readStatus,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      image: image ?? this.image,
      timestamp: timestamp ?? this.timestamp,
      readStatus: readStatus ?? this.readStatus,
    );
  }
}
