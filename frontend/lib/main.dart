import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (AppConstants.supabaseUrl.isEmpty ||
      AppConstants.supabasePublishableKey.isEmpty) {
    throw Exception(
      'Faltan SUPABASE_URL o SUPABASE_PUBLISHABLE_KEY. '
      'Pásalos con --dart-define al correr Flutter.',
    );
  }

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabasePublishableKey,
  );

  // Inicializar Notificaciones Push y Locales
  LocalNotificationService.init(AppRouter.navigatorKey);
  
  final pushService = PushNotificationService();
  await pushService.init();

  runApp(
    const ProviderScope(
      child: RentApp(),
    ),
  );
}
