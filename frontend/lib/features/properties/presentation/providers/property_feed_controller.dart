import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/property_remote_datasource.dart';
import '../../data/repositories/property_repository_impl.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../../domain/usecases/get_recommendations_usecase.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

final propertyRemoteDataSourceProvider =
    Provider<PropertyRemoteDataSource>((ref) {
  return PropertyRemoteDataSource();
});

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepositoryImpl(
    remoteDataSource: ref.watch(propertyRemoteDataSourceProvider),
  );
});

final getRecommendationsUseCaseProvider =
    Provider<GetRecommendationsUseCase>((ref) {
  return GetRecommendationsUseCase(ref.watch(propertyRepositoryProvider));
});

final propertyFeedProvider = FutureProvider.autoDispose<List<Property>>((ref) async {
  // Importante: al cambiar login/logout, este provider se recalcula.
  ref.watch(currentAuthStateProvider);

  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return <Property>[];

  return ref.watch(getRecommendationsUseCaseProvider).call();
});
