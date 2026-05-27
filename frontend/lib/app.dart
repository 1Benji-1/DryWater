import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Widget raíz de Rent App.
class RentApp extends StatelessWidget {
  const RentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rent App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
