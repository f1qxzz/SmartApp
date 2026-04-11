class FinanceEntryEntity {
  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;

  const FinanceEntryEntity({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  factory FinanceEntryEntity.fromJson(Map<String, dynamic> json) {
    return FinanceEntryEntity(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toRequest() => {
        'amount': amount,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
      };
}
