import '../../../properties/domain/entities/property.dart';
import '../repositories/match_repository.dart';

class GetMatchesUseCase {
  final MatchRepository _repository;

  const GetMatchesUseCase(this._repository);

  Future<List<Property>> call() {
    return _repository.getMatches();
  }
}
