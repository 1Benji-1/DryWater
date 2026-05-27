import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interceptor global de autenticación.
///
/// Inyecta automáticamente:
/// Authorization: Bearer <access_token>
///
/// Así ninguna pantalla ni datasource tiene que mandar tokens manualmente.
class AuthInterceptor extends Interceptor {
  final SupabaseClient _supabase;

  AuthInterceptor({
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _supabase.auth.currentSession?.accessToken;

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}
