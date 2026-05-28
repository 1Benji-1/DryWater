import '../entities/swipe_result.dart';

abstract class SwipeRepository {
  Future<SwipeResult> sendSwipe({
    required String propertyId,
    required String action,
  });
}
