import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? get _redirectUrl {
    final value = AppConstants.supabaseRedirectUrl.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Ingresa un correo válido.';
        _successMessage = null;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'La contraseña debe tener mínimo 6 caracteres.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isLoginMode) {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await _supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: _redirectUrl,
          data: {
            'full_name': fullName.isEmpty ? email.split('@').first : fullName,
          },
        );

        if (_supabase.auth.currentSession == null) {
          setState(() {
            _successMessage =
                'Cuenta creada. Revisa tu correo para confirmar el registro.';
          });
        }
      }
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error inesperado: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectUrl,
      );
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      setState(() {
        _errorMessage =
            'No se pudo iniciar sesión con Google. Revisa la configuración OAuth.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLoginMode ? 'Iniciar sesión' : 'Crear cuenta';
    final buttonText = _isLoginMode ? 'Entrar' : 'Registrarme';
    final switchText = _isLoginMode
        ? '¿No tienes cuenta? Regístrate'
        : '¿Ya tienes cuenta? Inicia sesión';

    return Scaffold(
      body: Center(
        child: Container(
          width: 430,
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.home_work, size: 72, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Rent App',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 18),
                ),
                const SizedBox(height: 28),

                if (!_isLoginMode) ...[
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onSubmitted: (_) => _isLoading ? null : _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_successMessage != null) ...[
                  Text(
                    _successMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(buttonText),
                  ),
                ),

                const SizedBox(height: 14),

                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Continuar con Google'),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _isLoading ? null : _toggleMode,
                  child: Text(switchText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
