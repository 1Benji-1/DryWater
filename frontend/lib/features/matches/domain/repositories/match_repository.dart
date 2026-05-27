import '../../../properties/domain/entities/property.dart';

abstract class MatchRepository {
  Future<List<Property>> getMatches();
}
