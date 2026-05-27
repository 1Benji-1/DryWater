import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;

  const SignInUseCase(this._repository);

  Future<void> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
