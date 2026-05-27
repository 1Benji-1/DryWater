import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    const ProviderScope(
      child: RentApp(),
    ),
  );
}
