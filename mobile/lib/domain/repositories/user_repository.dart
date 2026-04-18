import 'package:smartlife_app/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<List<UserEntity>> getUsers({String? search});
  Future<UserEntity> updateUserRole(String userId, String role);
}
