class UserEntity {
  final String id;
  final String username;
  final String email;
  final String avatar;
  final String gender;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.avatar = '',
    this.gender = '',
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    final username = (json['username'] ?? json['name'] ?? '').toString();
    return UserEntity(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      username: username,
      email: (json['email'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
    );
  }

  UserEntity copyWith({
    String? id,
    String? username,
    String? email,
    String? avatar,
    String? gender,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'avatar': avatar,
        'gender': gender,
      };
}
