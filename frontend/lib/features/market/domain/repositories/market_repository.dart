import '../../data/dto/market_evaluation_dto.dart';

abstract class MarketRepository {
  Future<MarketEvaluationResult> evaluate({
    required double price,
    required String operationType,
    String? zone,
    String? propertyType,
  });
}
