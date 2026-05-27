import '../entities/onboarding_preferences.dart';

abstract class OnboardingRepository {
  Future<bool> savePreferences(OnboardingPreferences preferences);
}
