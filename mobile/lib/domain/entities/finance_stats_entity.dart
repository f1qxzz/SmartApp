class FinanceStatsEntity {
  final double daily;
  final double weekly;
  final double monthly;
  final double budget;
  final double remaining;
  final double percentageUsed;
  final List<(String category, double total)> categoryBreakdown;

  const FinanceStatsEntity({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.budget,
    required this.remaining,
    required this.percentageUsed,
    required this.categoryBreakdown,
  });

  factory FinanceStatsEntity.fromJson(Map<String, dynamic> json) {
    final breakdown = (json['categoryBreakdown'] as List? ?? [])
        .map((item) => (
              (item['_id'] ?? '').toString(),
              (item['total'] as num?)?.toDouble() ?? 0,
            ))
        .toList();

    return FinanceStatsEntity(
      daily: (json['daily'] as num?)?.toDouble() ?? 0,
      weekly: (json['weekly'] as num?)?.toDouble() ?? 0,
      monthly: (json['monthly'] as num?)?.toDouble() ?? 0,
      budget: (json['budget'] as num?)?.toDouble() ?? 0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      percentageUsed: (json['percentageUsed'] as num?)?.toDouble() ?? 0,
      categoryBreakdown: breakdown,
    );
  }
}
