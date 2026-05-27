import '../../domain/entities/onboarding_preferences.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDataSource _remoteDataSource;

  const OnboardingRepositoryImpl({
    required OnboardingRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<bool> savePreferences(OnboardingPreferences preferences) {
    return _remoteDataSource.savePreferences(preferences);
  }
}
