class UserEntity {
  final String id;
  final String username;
  final String email;
  final String avatar;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.avatar = '',
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    final username = (json['username'] ?? json['name'] ?? '').toString();
    return UserEntity(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      username: username,
      email: (json['email'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'avatar': avatar,
      };
}
