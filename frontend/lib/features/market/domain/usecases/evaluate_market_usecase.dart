import '../../data/dto/market_evaluation_dto.dart';
import '../repositories/market_repository.dart';

class EvaluateMarketUseCase {
  final MarketRepository _repository;

  const EvaluateMarketUseCase(this._repository);

  Future<MarketEvaluationResult> call({
    required double price,
    required String operationType,
    String? zone,
    String? propertyType,
  }) {
    return _repository.evaluate(
      price: price,
      operationType: operationType,
      zone: zone,
      propertyType: propertyType,
    );
  }
}
