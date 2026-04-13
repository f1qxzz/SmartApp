import 'package:smartlife_app/domain/entities/user_entity.dart';

class SessionAuthCache {
  static String? _token;
  static UserEntity? _user;

  static String? get token => _token;
  static UserEntity? get user => _user;

  static void setAuth({
    required String token,
    required UserEntity user,
  }) {
    _token = token;
    _user = user;
  }

  static void clear() {
    _token = null;
    _user = null;
  }
}
