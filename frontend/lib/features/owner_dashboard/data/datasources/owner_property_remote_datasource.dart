import '../../../../services/api_service.dart';
import '../../../properties/domain/entities/property.dart';

class OwnerPropertyRemoteDataSource {
  final ApiService _apiService;

  OwnerPropertyRemoteDataSource({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<List<Property>> getOwnerProperties() {
    return _apiService.fetchOwnerProperties();
  }
}
