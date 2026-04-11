import 'package:dio/dio.dart';

import 'package:smartlife_app/core/network/api_exception.dart';
import 'package:smartlife_app/core/network/dio_client.dart';

class AiService {
  AiService(this._dioClient);

  final DioClient _dioClient;

  Future<String> ask(String message) async {
    try {
      final response = await _dioClient.instance.post('/api/ai/chat', data: {'message': message});
      final data = Map<String, dynamic>.from(response.data as Map);
      final payload = Map<String, dynamic>.from(data['data'] as Map);
      return (payload['answer'] ?? '').toString();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
