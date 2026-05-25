import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/properties/domain/entities/property.dart';
import '../services/api_service.dart';

/// ID del usuario autenticado en Supabase.
final userIdProvider = Provider<String>((ref) {
  return Supabase.instance.client.auth.currentUser?.id ?? '';
});

/// Proveedor de API centralizado.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Propiedades recomendadas para el usuario autenticado.
final propertiesProvider = FutureProvider<List<Property>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId.isEmpty) return [];

  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchProperties();
});
