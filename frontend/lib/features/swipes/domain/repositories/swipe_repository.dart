abstract class SwipeRepository {
  Future<void> sendSwipe({
    required String propertyId,
    required String action,
  });
}
