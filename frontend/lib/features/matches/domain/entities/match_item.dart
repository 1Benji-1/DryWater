import '../../../properties/domain/entities/property.dart';

class MatchItem {
  final String id;
  final String status;
  final Property property;

  const MatchItem({
    required this.id,
    required this.status,
    required this.property,
  });
}
