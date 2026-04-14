import 'package:uuid/uuid.dart';

class ReminderEntity {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isCompleted;
  final String? category;

  const ReminderEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.isCompleted = false,
    this.category,
  });

  ReminderEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isCompleted,
    String? category,
  }) {
    return ReminderEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
    );
  }

  factory ReminderEntity.fromJson(Map<String, dynamic> json) {
    return ReminderEntity(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      dateTime: json['dateTime'] != null
          ? DateTime.tryParse(json['dateTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isCompleted': isCompleted,
      'category': category,
    };
  }

  bool get isOverdue => !isCompleted && DateTime.now().isAfter(dateTime);
}
