import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _remoteDataSource.currentUser;
    if (user == null) return null;

    return AppUser(
      id: user.id,
      email: user.email,
      fullName: user.userMetadata?['full_name']?.toString(),
      role: user.userMetadata?['role']?.toString() ?? 'buyer',
    );
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) {
    return _remoteDataSource.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
  }
}
