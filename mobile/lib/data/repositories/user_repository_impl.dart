import 'package:smartlife_app/data/services/user_service.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._userService);

  final UserService _userService;

  @override
  Future<List<UserEntity>> getUsers({String? search}) {
    return _userService.listUsers(search: search);
  }

  @override
  Future<UserEntity> updateUserRole(String userId, String role) {
    return _userService.updateRole(userId, role);
  }
}
