import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notifica a go_router cuando cambia la sesión de Supabase.
class AuthRefreshListenable extends ChangeNotifier {
  StreamSubscription<AuthState>? _subscription;

  AuthRefreshListenable() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
