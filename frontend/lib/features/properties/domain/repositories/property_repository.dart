import '../../../../services/api_service.dart';
import '../entities/property.dart';

abstract class PropertyRepository {
  Future<List<Property>> getRecommendations();
  Future<PropertyDetailData> getDetail(String propertyId);
}
