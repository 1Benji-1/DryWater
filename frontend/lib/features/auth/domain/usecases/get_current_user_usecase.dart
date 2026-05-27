import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  Future<AppUser?> call() {
    return _repository.getCurrentUser();
  }
}
