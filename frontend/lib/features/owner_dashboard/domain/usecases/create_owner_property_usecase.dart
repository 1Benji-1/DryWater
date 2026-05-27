import '../../../../services/api_service.dart';

class CreateOwnerPropertyUseCase {
  final ApiService _apiService;

  const CreateOwnerPropertyUseCase(this._apiService);

  Future<void> call(OwnerPropertyCreateInput input) async {
    await _apiService.createOwnerProperty(input);
  }
}
