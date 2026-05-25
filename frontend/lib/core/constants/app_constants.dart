/// Constantes globales de la app.
///
/// Ejemplo Linux/Chrome:
/// flutter run -d linux \
///   --dart-define=API_BASE_URL=http://127.0.0.1:8000 \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxx
class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Usado para confirmación de email/OAuth.
  ///
  /// Para Chrome normalmente puedes dejarlo vacío.
  /// Para Android/iOS luego configuraremos deep links.
  static const String supabaseRedirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
    defaultValue: '',
  );

  static const int defaultPageSize = 20;
}
