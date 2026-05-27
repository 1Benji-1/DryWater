import '../../domain/repositories/market_repository.dart';
import '../datasources/market_remote_datasource.dart';
import '../dto/market_evaluation_dto.dart';

class MarketRepositoryImpl implements MarketRepository {
  final MarketRemoteDataSource _remoteDataSource;

  const MarketRepositoryImpl({
    required MarketRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<MarketEvaluationResult> evaluate({
    required double price,
    required String operationType,
    String? zone,
    String? propertyType,
  }) {
    return _remoteDataSource.evaluate(
      price: price,
      operationType: operationType,
      zone: zone,
      propertyType: propertyType,
    );
  }
}
