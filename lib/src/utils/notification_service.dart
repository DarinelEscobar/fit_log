import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(initializationSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> scheduleRestDone(int seconds) async {
    final scheduledDate = DateTime.now().add(Duration(seconds: seconds));
    const androidDetails = AndroidNotificationDetails(
      'rest_timer',
      'Rest Timer',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 800, 200, 800]),
    );
    const iosDetails = DarwinNotificationDetails(presentSound: false);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.schedule(
      0,
      'Descanso finalizado',
      'Vuelve al ejercicio',
      scheduledDate,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelRest() async {
    await _plugin.cancel(0);
  }
}
