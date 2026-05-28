import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/property_remote_datasource.dart';
import '../../data/repositories/property_repository_impl.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../../domain/usecases/get_recommendations_usecase.dart';

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

final propertyFeedProvider = FutureProvider<List<Property>>((ref) async {
  return ref.watch(getRecommendationsUseCaseProvider).call();
});
