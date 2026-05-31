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
    final goingToIntro = path == RouteNames.intro;

    if (!isAuthenticated && !goingToLogin && !goingToIntro) {
      return RouteNames.login;
    }

    if (isAuthenticated && (goingToLogin || goingToIntro)) {
      return RouteNames.onboarding;
    }

    return null;
  }
}
