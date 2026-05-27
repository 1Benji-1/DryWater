import 'package:dio/dio.dart';

/// Error estándar de la capa de red.
///
/// Todas las features deben transformar errores Dio en este tipo,
/// para que la UI no dependa directamente de detalles HTTP.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final nestedError = data['error'];

      if (nestedError is Map<String, dynamic>) {
        return ApiException(
          message: nestedError['message']?.toString() ??
              'Error de conexión con el servidor.',
          statusCode: statusCode,
          details: data,
        );
      }

      return ApiException(
        message: data['message']?.toString() ??
            data['detail']?.toString() ??
            'Error de conexión con el servidor.',
        statusCode: statusCode,
        details: data,
      );
    }

    return ApiException(
      message: error.message ?? 'Error de conexión con el servidor.',
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    if (statusCode == null) return message;
    return '$message (HTTP $statusCode)';
  }
}
