import 'package:dio/dio.dart';

/// Interceptor global de errores.
///
/// Por ahora no transforma directamente el error para no ocultar información.
/// Los datasources convierten DioException a ApiException.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
