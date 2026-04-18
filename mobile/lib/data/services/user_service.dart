import 'package:smartlife_app/core/network/api_exception.dart';
import 'package:smartlife_app/core/network/dio_client.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';

class UserService {
  UserService(this._dioClient);

  final DioClient _dioClient;

  Future<List<UserEntity>> listUsers({String? search}) async {
    try {
      final response = await _dioClient.instance.get(
        '/api/users',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => UserEntity.fromJson(json)).toList();
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserEntity> updateRole(String userId, String role) async {
    try {
      final response = await _dioClient.instance.put(
        '/api/users/$userId/role',
        data: {'role': role},
      );

      final userJson = response.data['data'];
      return UserEntity.fromJson(userJson);
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
