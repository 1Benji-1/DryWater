import '../../../properties/domain/entities/property.dart';

abstract class OwnerPropertyRepository {
  Future<List<Property>> getOwnerProperties();
}
