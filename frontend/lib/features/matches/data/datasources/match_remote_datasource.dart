import '../../../../services/api_service.dart';
import '../../../properties/domain/entities/property.dart';

class MatchRemoteDataSource {
  final ApiService _apiService;

  MatchRemoteDataSource({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<List<Property>> getMatches() {
    return _apiService.fetchMatches();
  }
}
