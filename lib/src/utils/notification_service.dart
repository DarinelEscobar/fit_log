// lib/src/utils/notification_service.dart
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static const String _restChannelId = 'rest_timer_v3_alarm';
  static const String _restChannelName = 'Rest Timer';
  static const String _restChannelDescription = 'Workout rest timer alerts';

  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    tz.initializeTimeZones();
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(initializationSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    _isInitialized = true;
  }

  static Future<void> scheduleRestDone(
    int seconds, {
    int notificationId = 0,
    DateTime? scheduledAt,
  }) async {
    if (!_isInitialized) {
      return;
    }
    final scheduledDate = tz.TZDateTime.from(
      scheduledAt ?? DateTime.now(),
      tz.local,
    ).add(Duration(seconds: seconds));
    final androidDetails = AndroidNotificationDetails(
      _restChannelId,
      _restChannelName,
      channelDescription: _restChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: Int64List.fromList([0, 1200, 250, 1200, 250, 1800]),
    );
    const iosDetails = DarwinNotificationDetails(
      presentSound: false,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.cancel(notificationId);
    await _plugin.zonedSchedule(
      notificationId,
      'Descanso finalizado',
      'Vuelve al ejercicio',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelRest({int notificationId = 0}) async {
    if (!_isInitialized) {
      return;
    }
    await _plugin.cancel(notificationId);
  }
}
