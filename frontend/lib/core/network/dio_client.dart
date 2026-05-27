import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

/// Fábrica central de Dio.
///
/// Todo acceso HTTP debe salir de aquí o de ApiClient.
class DioClient {
  DioClient._();

  static Dio create({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 10),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(ErrorInterceptor());

    return dio;
  }
}
