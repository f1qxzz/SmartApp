class UserEntity {
  final String id;
  final String username;
  final String name;
  final String email;
  final String avatar;
  final String gender;
  final double monthlyBudget;

  const UserEntity({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.avatar = '',
    this.gender = '',
    this.monthlyBudget = 0,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      name: (json['name'] ?? json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      monthlyBudget: double.tryParse(json['monthlyBudget']?.toString() ?? '0') ?? 0,
    );
  }

  UserEntity copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? avatar,
    String? gender,
    double? monthlyBudget,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      gender: gender ?? this.gender,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'avatar': avatar,
        'gender': gender,
        'monthlyBudget': monthlyBudget,
      };
}
