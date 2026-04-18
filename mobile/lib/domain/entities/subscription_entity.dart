class SubscriptionEntity {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String billingCycle;
  final String icon;
  final String color;
  final String status;
  final DateTime? nextBillingDate;

  const SubscriptionEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    this.billingCycle = 'monthly',
    this.icon = 'card_giftcard_rounded',
    this.color = '#6366F1',
    this.status = 'active',
    this.nextBillingDate,
  });

  factory SubscriptionEntity.fromJson(Map<String, dynamic> json) {
    return SubscriptionEntity(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      billingCycle: (json['billingCycle'] ?? 'monthly').toString(),
      icon: (json['icon'] ?? 'card_giftcard_rounded').toString(),
      color: (json['color'] ?? '#6366F1').toString(),
      status: (json['status'] ?? 'active').toString(),
      nextBillingDate: json['nextBillingDate'] != null 
          ? DateTime.tryParse(json['nextBillingDate'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'billingCycle': billingCycle,
        'icon': icon,
        'color': color,
        'status': status,
        'nextBillingDate': nextBillingDate?.toIso8601String(),
      };
}
