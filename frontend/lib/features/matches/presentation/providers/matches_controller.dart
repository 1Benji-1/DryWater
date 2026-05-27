import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../properties/domain/entities/property.dart';
import '../../data/datasources/match_remote_datasource.dart';
import '../../data/repositories/match_repository_impl.dart';
import '../../domain/repositories/match_repository.dart';
import '../../domain/usecases/get_matches_usecase.dart';

final matchRemoteDataSourceProvider = Provider<MatchRemoteDataSource>((ref) {
  return MatchRemoteDataSource();
});

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepositoryImpl(
    remoteDataSource: ref.watch(matchRemoteDataSourceProvider),
  );
});

final getMatchesUseCaseProvider = Provider<GetMatchesUseCase>((ref) {
  return GetMatchesUseCase(ref.watch(matchRepositoryProvider));
});

final matchesControllerProvider = FutureProvider<List<Property>>((ref) {
  return ref.watch(getMatchesUseCaseProvider).call();
});
