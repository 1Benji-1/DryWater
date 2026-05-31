import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void init(GlobalKey<NavigatorState> navigatorKey) {
    // Inicialización para Android (usa el icono predeterminado '@mipmap/ic_launcher' o uno creado)
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          // Si el usuario toca la notificación, lanzar el modal global de alerta
          _showGlobalAlertModal(navigatorKey, response.payload!);
        }
      },
    );
  }

  static Future<void> showSimulatedNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'emergencies_channel',
        'Alertas de Emergencia',
        channelDescription: 'Canal crítico para alertas de clima extremo',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        color: Colors.red,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      0, // ID de la notificación
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Se lanza cuando el usuario hace tap en la notificación
  static void _showGlobalAlertModal(GlobalKey<NavigatorState> navigatorKey, String payload) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡ALERTA EXTREMA!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          payload,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red[900]),
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO, LEER PROTOCOLOS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Método público para lanzar el modal forzado si el usuario ya tenía la app abierta
  static void showGlobalAlertModal(GlobalKey<NavigatorState> navigatorKey, String payload) {
    _showGlobalAlertModal(navigatorKey, payload);
  }
}
