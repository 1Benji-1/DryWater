import '../../../../services/api_service.dart';
import '../../domain/entities/property.dart';

class PropertyRemoteDataSource {
  final ApiService _apiService;

  PropertyRemoteDataSource({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<List<Property>> getRecommendations() {
    return _apiService.fetchProperties();
  }

  Future<PropertyDetailData> getDetail(String propertyId) {
    return _apiService.fetchPropertyDetail(propertyId);
  }
}
