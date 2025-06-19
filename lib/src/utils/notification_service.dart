// lib/src/utils/notification_service.dart
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  NotificationService._();
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(initializationSettings);
  }

  static Future<void> scheduleRestDone(int seconds) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    final androidDetails = AndroidNotificationDetails(
      'rest_timer',
      'Rest Timer',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 800, 200, 800]),
    );
    final iosDetails = DarwinNotificationDetails(presentSound: false);
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.zonedSchedule(
      0,
      'Descanso finalizado',
      'Vuelve al ejercicio',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelRest() async {
    await _plugin.cancel(0);
  }
}
