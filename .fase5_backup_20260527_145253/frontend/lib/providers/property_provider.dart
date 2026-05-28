import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/dio_client.dart';
import '../features/properties/domain/entities/property.dart';
import '../features/properties/presentation/providers/property_feed_controller.dart';
import '../services/api_service.dart';

/// ID del usuario autenticado en Supabase.
///
/// Se mantiene por compatibilidad con pantallas existentes.
final userIdProvider = Provider<String>((ref) {
  return Supabase.instance.client.auth.currentUser?.id ?? '';
});

/// Dio centralizado.
final dioProvider = Provider<Dio>((ref) {
  return DioClient.create();
});

/// Proveedor legacy de ApiService.
///
/// Temporalmente se conserva para no romper pantallas existentes.
/// La migración nueva debe preferir datasources/repositories/usecases.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(dio: ref.watch(dioProvider));
});

/// Propiedades recomendadas para el usuario autenticado.
///
/// Ahora delega al provider de la feature properties.
final propertiesProvider = FutureProvider<List<Property>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId.isEmpty) return [];

  return ref.watch(propertyFeedProvider.future);
});
