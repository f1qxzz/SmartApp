import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:smartlife_app/core/config/env_config.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/core/storage/session_auth_cache.dart';

class DioClient {
  DioClient() {
    debugPrint('[API] Base URL: ${EnvConfig.apiBaseUrl}');
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = SessionAuthCache.token ?? HiveService.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('[API] ${options.method} ${options.path}');
          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint(
            '[API][ERROR] ${error.requestOptions.method} ${error.requestOptions.path} -> '
            '${error.response?.statusCode} ${error.response?.data}',
          );
          handler.next(error);
        },
      ),
    );

    if (kIsWeb) {
      final dynamic adapter = _dio.httpClientAdapter;
      try {
        adapter.withCredentials = true;
      } catch (_) {
        debugPrint(
          '[API] Browser adapter tidak mendukung withCredentials. '
          'Cookie auth mungkin tidak terkirim lintas origin.',
        );
      }
    }
  }

  late final Dio _dio;

  Dio get instance => _dio;
}
