import '../../../properties/domain/entities/property.dart';
import '../../domain/repositories/owner_property_repository.dart';
import '../datasources/owner_property_remote_datasource.dart';

class OwnerPropertyRepositoryImpl implements OwnerPropertyRepository {
  final OwnerPropertyRemoteDataSource _remoteDataSource;

  const OwnerPropertyRepositoryImpl({
    required OwnerPropertyRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Property>> getOwnerProperties() {
    return _remoteDataSource.getOwnerProperties();
  }
}
