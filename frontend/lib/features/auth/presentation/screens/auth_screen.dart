import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../services/api_service.dart';

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
  bool _obscurePassword = true;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _syncProfileIfSessionExists() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return;

    await ApiService().fetchProfile();
  }

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
        await _syncProfileIfSessionExists();
      } else {
        await _supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: _redirectUrl,
          data: {
            'full_name': fullName.isEmpty ? email.split('@').first : fullName,
          },
        );

        await _syncProfileIfSessionExists();

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD2ECD9), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF10471D)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLoginMode ? '¡hola!' : '¡bienvenido!';
    final buttonText = _isLoginMode ? 'Iniciar Sesión' : 'Registrarse';
    final switchText = _isLoginMode
        ? '¿No tienes cuenta? Regístrate'
        : '¿Ya tienes cuenta? Inicia sesión';

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Web wrapper background
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xFFD2ECD9), // Top background matching the original
            boxShadow: [
              BoxShadow(
                color: Color(0x66000000), // Black with 40% opacity
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Abstract background shapes to mimic the reference image
              Positioned(
                top: -50,
                left: -50,
                child: Transform.rotate(
                  angle: -0.5,
                  child: Container(
                    width: 200,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0x7FC3E7C9), // 50% opacity
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 150,
                right: -80,
                child: Transform.rotate(
                  angle: -0.5,
                  child: Container(
                    width: 250,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0x7FC3E7C9), // 50% opacity
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 250,
                left: -30,
                child: Transform.rotate(
                  angle: -0.5,
                  child: Container(
                    width: 150,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0x7FC3E7C9), // 50% opacity
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              // Main Content
              Column(
                children: [
                  // Top section (Logo)
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              // Placeholder in case asset is not found
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x19000000), // 10% opacity
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    )
                                  ]
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: Color(0xFF246D34),
                                  size: 40,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'DryWater',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Georgia',
                              fontFamilyFallback: ['Didot', 'Times New Roman', 'serif'],
                              color: Color(0xFF10471D),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom section (White card)
                  Expanded(
                    flex: 7,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF10471D),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (!_isLoginMode) ...[
                              _buildTextField(
                                controller: _nameController,
                                hint: 'Nombre completo',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _buildTextField(
                              controller: _emailController,
                              hint: 'Correo electrónico',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'Contraseña',
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            const SizedBox(height: 24),
                            
                            if (_errorMessage != null) ...[
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10471D),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0x9910471D), // 60% opacity
                                disabledForegroundColor: const Color(0x99FFFFFF), // 60% opacity
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      buttonText,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 24),
                            
                            // "or" section
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'o',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            Text(
                              'Inicia sesión con tus redes sociales',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(
                                  color: Colors.red,
                                  iconData: Icons.g_mobiledata,
                                  onPressed: _isLoading ? null : _signInWithGoogle,
                                ),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  color: Colors.amber,
                                  iconData: Icons.apple,
                                  onPressed: null, // Placeholder
                                ),
                                const SizedBox(width: 16),
                                _buildSocialButton(
                                  color: Colors.blue,
                                  iconData: Icons.facebook,
                                  onPressed: null, // Placeholder
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            TextButton(
                              onPressed: _isLoading ? null : _toggleMode,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF246D34),
                              ),
                              child: Text(
                                switchText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Color color,
    required IconData iconData,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Center(
          child: Icon(iconData, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
