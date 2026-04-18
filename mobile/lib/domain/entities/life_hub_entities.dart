class Habit {
  final String id;
  final String title;
  final String icon;
  final int streak;
  final bool isCompletedToday;
  final String frequency; // 'daily', 'weekly'

  Habit({
    required this.id,
    required this.title,
    required this.icon,
    this.streak = 0,
    this.isCompletedToday = false,
    this.frequency = 'daily',
  });

  Habit copyWith({
    String? title,
    String? icon,
    int? streak,
    bool? isCompletedToday,
    String? frequency,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      streak: streak ?? this.streak,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      frequency: frequency ?? this.frequency,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'icon': icon,
    'streak': streak,
    'isCompletedToday': isCompletedToday,
    'frequency': frequency,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    title: json['title'],
    icon: json['icon'],
    streak: json['streak'] ?? 0,
    isCompletedToday: json['isCompletedToday'] ?? false,
    frequency: json['frequency'] ?? 'daily',
  );
}

class LifeGoal {
  final String id;
  final String title;
  final double progress; // 0.0 to 1.0
  final String deadline;
  final String category;
  final bool isCompleted;

  LifeGoal({
    required this.id,
    required this.title,
    required this.progress,
    required this.deadline,
    this.category = 'General',
    this.isCompleted = false,
  });

  LifeGoal copyWith({
    String? title,
    double? progress,
    String? deadline,
    String? category,
    bool? isCompleted,
  }) {
    return LifeGoal(
      id: id,
      title: title ?? this.title,
      progress: progress ?? this.progress,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'progress': progress,
    'deadline': deadline,
    'category': category,
    'isCompleted': isCompleted,
  };

  factory LifeGoal.fromJson(Map<String, dynamic> json) => LifeGoal(
    id: json['id'],
    title: json['title'],
    progress: (json['progress'] ?? 0.0).toDouble(),
    deadline: json['deadline'],
    category: json['category'] ?? 'General',
    isCompleted: json['isCompleted'] ?? false,
  );
}
