import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;

  static ApiException fromDio(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return ApiException(message);
        }
      }

      return ApiException(error.message ?? 'Network error');
    }

    return const ApiException('Unexpected error');
  }
}
