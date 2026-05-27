import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/owner_dashboard/presentation/dashboard_screen.dart';
import '../../features/owner_dashboard/presentation/owner_property_form_screen.dart';
import '../../features/properties/presentation/screens/property_detail_screen.dart';
import '../../features/properties/presentation/screens/property_feed_screen.dart';
import '../router/auth_guard.dart';
import '../router/auth_refresh_listenable.dart';
import '../router/route_names.dart';

/// Router central de la aplicación.
///
/// Toda navegación principal debe pasar por aquí.
class AppRouter {
  AppRouter._();

  static final AuthRefreshListenable _authRefresh = AuthRefreshListenable();

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.login,
    refreshListenable: _authRefresh,
    redirect: (context, state) => AuthGuard.redirect(state),
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const PropertyFeedScreen(),
      ),
      GoRoute(
        name: RouteNames.propertyDetailName,
        path: RouteNames.propertyDetailPath,
        builder: (context, state) {
          final propertyId = state.pathParameters['id'] ?? '';
          return PropertyDetailScreen(propertyId: propertyId);
        },
      ),
      GoRoute(
        path: RouteNames.matches,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.ownerDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.ownerCreateProperty,
        builder: (context, state) => const OwnerPropertyFormScreen(),
      ),
    ],
  );
}
