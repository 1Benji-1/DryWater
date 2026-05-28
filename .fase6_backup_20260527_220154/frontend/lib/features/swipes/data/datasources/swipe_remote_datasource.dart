import '../../../../services/api_service.dart';

class SwipeRemoteDataSource {
  final ApiService _apiService;

  SwipeRemoteDataSource({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<void> sendSwipe({
    required String propertyId,
    required String action,
  }) {
    return _apiService.sendSwipeAction(propertyId, action);
  }
}
