import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../properties/domain/entities/property.dart';
import '../../data/datasources/owner_property_remote_datasource.dart';
import '../../data/repositories/owner_property_repository_impl.dart';
import '../../domain/repositories/owner_property_repository.dart';
import '../../domain/usecases/get_owner_properties_usecase.dart';

final ownerPropertyRemoteDataSourceProvider =
    Provider<OwnerPropertyRemoteDataSource>((ref) {
  return OwnerPropertyRemoteDataSource();
});

final ownerPropertyRepositoryProvider =
    Provider<OwnerPropertyRepository>((ref) {
  return OwnerPropertyRepositoryImpl(
    remoteDataSource: ref.watch(ownerPropertyRemoteDataSourceProvider),
  );
});

final getOwnerPropertiesUseCaseProvider =
    Provider<GetOwnerPropertiesUseCase>((ref) {
  return GetOwnerPropertiesUseCase(ref.watch(ownerPropertyRepositoryProvider));
});

final ownerPropertiesControllerProvider = FutureProvider<List<Property>>((ref) {
  return ref.watch(getOwnerPropertiesUseCaseProvider).call();
});
