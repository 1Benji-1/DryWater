import 'package:dio/dio.dart';

import 'dio_client.dart';

/// Cliente API base.
///
/// Sirve como punto único para inyectar Dio en datasources.
class ApiClient {
  final Dio dio;

  ApiClient({
    Dio? dio,
  }) : dio = dio ?? DioClient.create();
}
