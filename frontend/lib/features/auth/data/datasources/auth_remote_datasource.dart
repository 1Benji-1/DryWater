import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  final SupabaseClient _supabase;

  AuthRemoteDataSource({
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
      },
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
