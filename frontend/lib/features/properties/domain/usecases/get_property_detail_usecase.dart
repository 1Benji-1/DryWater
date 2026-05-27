import '../../../../services/api_service.dart';
import '../repositories/property_repository.dart';

class GetPropertyDetailUseCase {
  final PropertyRepository _repository;

  const GetPropertyDetailUseCase(this._repository);

  Future<PropertyDetailData> call(String propertyId) {
    return _repository.getDetail(propertyId);
  }
}
