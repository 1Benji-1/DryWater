import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'route_names.dart';

/// Guard central de autenticación.
class AuthGuard {
  AuthGuard._();

  static bool get isAuthenticated {
    return Supabase.instance.client.auth.currentSession != null;
  }

  static String? redirect(GoRouterState state) {
    final path = state.uri.path;
    final goingToLogin = path == RouteNames.login;

    if (!isAuthenticated && !goingToLogin) {
      return RouteNames.login;
    }

    if (isAuthenticated && goingToLogin) {
      return RouteNames.onboarding;
    }

    return null;
  }
}
