import '../../../../services/api_service.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/property_remote_datasource.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyRemoteDataSource _remoteDataSource;

  const PropertyRepositoryImpl({
    required PropertyRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Property>> getRecommendations() {
    return _remoteDataSource.getRecommendations();
  }

  @override
  Future<PropertyDetailData> getDetail(String propertyId) {
    return _remoteDataSource.getDetail(propertyId);
  }
}
