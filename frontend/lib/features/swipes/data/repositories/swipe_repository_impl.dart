import '../../domain/entities/swipe_result.dart';
import '../../domain/repositories/swipe_repository.dart';
import '../datasources/swipe_remote_datasource.dart';

class SwipeRepositoryImpl implements SwipeRepository {
  final SwipeRemoteDataSource _remoteDataSource;

  const SwipeRepositoryImpl({
    required SwipeRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<SwipeResult> sendSwipe({
    required String propertyId,
    required String action,
  }) {
    return _remoteDataSource.sendSwipe(propertyId: propertyId, action: action);
  }
}
