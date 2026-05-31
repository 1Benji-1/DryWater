import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // 1. Pedir permiso al usuario (necesario en iOS/Web, Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      
      // 2. Obtener el token único del dispositivo
      String? token;
      try {
        if (kIsWeb) {
          // Nota para Web: En un proyecto real necesitas pasar un VAPID key aquí.
          // Por ahora obtendremos el token normal, puede fallar si Firebase no está full configurado en web
          token = await _fcm.getToken();
        } else {
          token = await _fcm.getToken();
        }
      } catch (e) {
        debugPrint('Error obteniendo FCM Token: $e');
      }

      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToSupabase(token);
      }

      // 3. Escuchar cuando el token cambie (por seguridad)
      _fcm.onTokenRefresh.listen(_saveTokenToSupabase);

      // 4. (Opcional) Escuchar notificaciones cuando la app está abierta
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Mensaje recibido en primer plano: ${message.notification?.title}');
      });

    } else {
      debugPrint('Permiso de notificaciones denegado.');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', user.id);
        debugPrint('FCM Token guardado en Supabase.');
      } catch (e) {
        debugPrint('Error guardando token en Supabase: $e');
      }
    }
  }
}
