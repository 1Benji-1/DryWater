import '../../../../services/api_service.dart';
import '../../domain/entities/swipe_result.dart';

class SwipeRemoteDataSource {
  final ApiService _apiService;

  SwipeRemoteDataSource({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<SwipeResult> sendSwipe({
    required String propertyId,
    required String action,
  }) {
    return _apiService.sendSwipeAction(propertyId, action);
  }
}
