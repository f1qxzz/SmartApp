class SavingsGoalEntity {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String color;
  final String icon;

  const SavingsGoalEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.color = '#6366F1',
    this.icon = 'wallet_rounded',
  });

  factory SavingsGoalEntity.fromJson(Map<String, dynamic> json) {
    return SavingsGoalEntity(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      targetAmount: double.tryParse(json['targetAmount']?.toString() ?? '0') ?? 0,
      currentAmount: double.tryParse(json['currentAmount']?.toString() ?? '0') ?? 0,
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'].toString()) : null,
      color: (json['color'] ?? '#6366F1').toString(),
      icon: (json['icon'] ?? 'wallet_rounded').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline?.toIso8601String(),
        'color': color,
        'icon': icon,
      };

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
}
