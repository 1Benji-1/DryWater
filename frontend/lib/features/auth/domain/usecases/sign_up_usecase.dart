import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  const SignUpUseCase(this._repository);

  Future<void> call({
    required String email,
    required String password,
    String? fullName,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
  }
}
