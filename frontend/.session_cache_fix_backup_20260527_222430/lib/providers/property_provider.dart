import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../features/properties/domain/entities/property.dart';
import '../features/properties/presentation/providers/property_feed_controller.dart';
import '../services/api_service.dart';

/// Dio centralizado.
final dioProvider = Provider<Dio>((ref) {
  return DioClient.create();
});

/// Proveedor legacy de ApiService.
///
/// Se conserva para pantallas existentes.
/// El token se agrega automáticamente mediante AuthInterceptor.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(dio: ref.watch(dioProvider));
});

/// Propiedades recomendadas para el usuario autenticado.
///
/// La identidad ya no viene de un user_id manual.
/// El backend obtiene el usuario desde Authorization: Bearer <token>.
final propertiesProvider = FutureProvider<List<Property>>((ref) async {
  return ref.watch(propertyFeedProvider.future);
});
