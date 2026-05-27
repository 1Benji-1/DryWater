/// Nombres y paths centralizados de rutas.
class RouteNames {
  RouteNames._();

  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String matches = '/matches';
  static const String ownerDashboard = '/owner';
  static const String ownerCreateProperty = '/owner/create';
  static const String market = '/market';

  static const String propertyDetailName = 'property-detail';
  static const String propertyDetailPath = '/properties/:id';

  static String propertyDetail(String id) => '/properties/$id';
}
