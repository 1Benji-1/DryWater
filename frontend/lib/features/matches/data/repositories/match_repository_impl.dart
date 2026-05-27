import '../../../properties/domain/entities/property.dart';
import '../../domain/repositories/match_repository.dart';
import '../datasources/match_remote_datasource.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource _remoteDataSource;

  const MatchRepositoryImpl({
    required MatchRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Property>> getMatches() {
    return _remoteDataSource.getMatches();
  }
}
