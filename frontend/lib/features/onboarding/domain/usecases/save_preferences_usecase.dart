import '../entities/onboarding_preferences.dart';
import '../repositories/onboarding_repository.dart';

class SavePreferencesUseCase {
  final OnboardingRepository _repository;

  const SavePreferencesUseCase(this._repository);

  Future<bool> call(OnboardingPreferences preferences) {
    return _repository.savePreferences(preferences);
  }
}
