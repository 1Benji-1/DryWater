import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/onboarding_remote_datasource.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/usecases/save_preferences_usecase.dart';

final onboardingRemoteDataSourceProvider =
    Provider<OnboardingRemoteDataSource>((ref) {
  return OnboardingRemoteDataSource();
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(
    remoteDataSource: ref.watch(onboardingRemoteDataSourceProvider),
  );
});

final savePreferencesUseCaseProvider = Provider<SavePreferencesUseCase>((ref) {
  return SavePreferencesUseCase(ref.watch(onboardingRepositoryProvider));
});
