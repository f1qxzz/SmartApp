class UserEntity {
  final String id;
  final String username;
  final String name;
  final String email;
  final String avatar;
  final String role;
  final String gender;
  final double monthlyBudget;
  final DateTime? dateOfBirth;
  final String socialGithub;
  final String socialInstagram;
  final String socialDiscord;
  final String socialTelegram;
  final String socialSpotify;

  const UserEntity({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.avatar = '',
    this.role = 'user',
    this.gender = '',
    this.monthlyBudget = 0,
    this.dateOfBirth,
    this.socialGithub = '',
    this.socialInstagram = '',
    this.socialDiscord = '',
    this.socialTelegram = '',
    this.socialSpotify = '',
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    DateTime? dob;
    if (json['dateOfBirth'] != null) {
      dob = DateTime.tryParse(json['dateOfBirth'].toString());
    }

    return UserEntity(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      name: (json['name'] ?? json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      gender: (json['gender'] ?? '').toString(),
      monthlyBudget: double.tryParse(json['monthlyBudget']?.toString() ?? '0') ?? 0,
      dateOfBirth: dob,
      socialGithub: (json['socialGithub'] ?? '').toString(),
      socialInstagram: (json['socialInstagram'] ?? '').toString(),
      socialDiscord: (json['socialDiscord'] ?? '').toString(),
      socialTelegram: (json['socialTelegram'] ?? '').toString(),
      socialSpotify: (json['socialSpotify'] ?? '').toString(),
    );
  }

  UserEntity copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? avatar,
    String? role,
    String? gender,
    double? monthlyBudget,
    DateTime? dateOfBirth,
    String? socialGithub,
    String? socialInstagram,
    String? socialDiscord,
    String? socialTelegram,
    String? socialSpotify,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      socialGithub: socialGithub ?? this.socialGithub,
      socialInstagram: socialInstagram ?? this.socialInstagram,
      socialDiscord: socialDiscord ?? this.socialDiscord,
      socialTelegram: socialTelegram ?? this.socialTelegram,
      socialSpotify: socialSpotify ?? this.socialSpotify,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'avatar': avatar,
        'role': role,
        'gender': gender,
        'monthlyBudget': monthlyBudget,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'socialGithub': socialGithub,
        'socialInstagram': socialInstagram,
        'socialDiscord': socialDiscord,
        'socialTelegram': socialTelegram,
        'socialSpotify': socialSpotify,
      };
}
