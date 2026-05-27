import '../../../../services/api_service.dart';
import '../../domain/entities/onboarding_preferences.dart';

class OnboardingRemoteDataSource {
  final ApiService _apiService;

  OnboardingRemoteDataSource({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<bool> savePreferences(OnboardingPreferences preferences) {
    return _apiService.sendOnboarding(
      budget: preferences.budget,
      operationType: preferences.operationType,
      preferredZone: preferences.preferredZone,
    );
  }
}
