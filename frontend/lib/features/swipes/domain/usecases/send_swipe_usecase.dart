import '../entities/swipe_result.dart';
import '../repositories/swipe_repository.dart';

class SendSwipeUseCase {
  final SwipeRepository _repository;

  const SendSwipeUseCase(this._repository);

  Future<SwipeResult> call({
    required String propertyId,
    required String action,
  }) {
    return _repository.sendSwipe(propertyId: propertyId, action: action);
  }
}
