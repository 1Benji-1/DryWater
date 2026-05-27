import '../../../properties/domain/entities/property.dart';
import '../repositories/owner_property_repository.dart';

class GetOwnerPropertiesUseCase {
  final OwnerPropertyRepository _repository;

  const GetOwnerPropertiesUseCase(this._repository);

  Future<List<Property>> call() {
    return _repository.getOwnerProperties();
  }
}
