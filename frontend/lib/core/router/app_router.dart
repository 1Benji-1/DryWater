import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/intro/presentation/screens/intro_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../router/auth_guard.dart';
import '../router/auth_refresh_listenable.dart';
import '../router/route_names.dart';

/// Router central de la aplicación.
class AppRouter {
  AppRouter._();

  static final AuthRefreshListenable _authRefresh = AuthRefreshListenable();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RouteNames.intro,
    refreshListenable: _authRefresh,
    redirect: (context, state) => AuthGuard.redirect(state),
    routes: [
      GoRoute(
        path: RouteNames.intro,
        builder: (context, state) => const IntroScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
}
