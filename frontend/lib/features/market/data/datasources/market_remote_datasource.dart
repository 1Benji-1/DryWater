import '../../../../services/api_service.dart';
import '../dto/market_evaluation_dto.dart';

class MarketRemoteDataSource {
  final ApiService _apiService;

  MarketRemoteDataSource({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<MarketEvaluationResult> evaluate({
    required double price,
    required String operationType,
    String? zone,
    String? propertyType,
  }) {
    return _apiService.evaluateMarketPrice(
      price,
      operationType,
      zone: zone,
      propertyType: propertyType,
    );
  }
}
