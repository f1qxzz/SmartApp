class AiMessageEntity {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const AiMessageEntity({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
