import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/market_remote_datasource.dart';
import '../../data/repositories/market_repository_impl.dart';
import '../../domain/repositories/market_repository.dart';
import '../../domain/usecases/evaluate_market_usecase.dart';

final marketRemoteDataSourceProvider = Provider<MarketRemoteDataSource>((ref) {
  return MarketRemoteDataSource();
});

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepositoryImpl(
    remoteDataSource: ref.watch(marketRemoteDataSourceProvider),
  );
});

final evaluateMarketUseCaseProvider = Provider<EvaluateMarketUseCase>((ref) {
  return EvaluateMarketUseCase(ref.watch(marketRepositoryProvider));
});
