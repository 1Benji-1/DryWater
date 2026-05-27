import '../entities/property.dart';
import '../repositories/property_repository.dart';

class GetRecommendationsUseCase {
  final PropertyRepository _repository;

  const GetRecommendationsUseCase(this._repository);

  Future<List<Property>> call() {
    return _repository.getRecommendations();
  }
}
