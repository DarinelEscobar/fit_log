// lib/src/utils/notification_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static final navigationRequest = ValueNotifier<String?>(null);
  static const checkInPayload = 'physique-check-in';
  static const String _restChannelId = 'rest_timer_v3_alarm';
  static const String _restChannelName = 'Rest Timer';
  static const String _restChannelDescription = 'Workout rest timer alerts';

  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    tz.initializeTimeZones();
    try {
      final zone = await const MethodChannel('fit_log/timezone')
          .invokeMethod<String>('getTimeZone');
      if (zone != null) tz.setLocalLocation(tz.getLocation(zone));
    } on Exception catch (error) {
      debugPrint('Device timezone unavailable: $error');
    }
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (response) {
      if (response.payload == checkInPayload) {
        navigationRequest.value = checkInPayload;
      }
    });
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.payload == checkInPayload) {
      navigationRequest.value = checkInPayload;
    }
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
    final reminder = await readCheckInReminder();
    if (reminder?['enabled'] == true) {
      await _scheduleCheckIn(
          reminder!['hour'] as int, reminder['minute'] as int);
    }
  }

  static Future<File> _reminderFile() async => File(
      '${(await getApplicationDocumentsDirectory()).path}/check_in_reminder.json');

  static Future<Map<String, dynamic>?> readCheckInReminder() async {
    final file = await _reminderFile();
    if (!await file.exists()) return null;
    return Map<String, dynamic>.from(
        jsonDecode(await file.readAsString()) as Map);
  }

  static Future<void> setCheckInReminder(
      {required bool enabled, required int hour, required int minute}) async {
    if (!_isInitialized) await init();
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Hora inválida');
    }
    if (enabled) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (await android?.requestNotificationsPermission() == false) {
        throw StateError('Activa el permiso de notificaciones en Ajustes.');
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (await ios?.requestPermissions(
              alert: true, badge: true, sound: true) ==
          false) {
        throw StateError('Activa el permiso de notificaciones en Ajustes.');
      }
    }
    for (var id = 60000; id <= 60031; id++) {
      await _plugin.cancel(id);
    }
    if (enabled) await _scheduleCheckIn(hour, minute);
    await (await _reminderFile()).writeAsString(
        jsonEncode({'enabled': enabled, 'hour': hour, 'minute': minute}),
        flush: true);
  }

  static Future<void> _scheduleCheckIn(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    final end = tz.TZDateTime(tz.local, 2026, 11, 1);
    if (!now.isBefore(end)) return;
    var date =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!date.isAfter(now)) {
      date = tz.TZDateTime(
          tz.local, date.year, date.month, date.day + 1, hour, minute);
    }
    while (date.isBefore(end)) {
      final abdomen = [DateTime.monday, DateTime.wednesday, DateTime.saturday]
          .contains(date.weekday);
      await _plugin.zonedSchedule(
        60000 + date.day,
        'Check-in de mañana',
        abdomen
            ? 'Peso y abdomen: antes de comer/beber. Revisa también la tolerancia de ayer.'
            : 'Registra tu peso antes de comer/beber y la tolerancia de ayer.',
        date,
        const NotificationDetails(
          android: AndroidNotificationDetails('check_in_v1', 'Check-in',
              channelDescription: 'Registro de peso, medidas y tolerancia',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: checkInPayload,
      );
      date = tz.TZDateTime(
          tz.local, date.year, date.month, date.day + 1, hour, minute);
    }
  }

  static Future<void> scheduleRestDone(
    int seconds, {
    int notificationId = 0,
    DateTime? scheduledAt,
    String? exerciseName,
    int? nextSetNumber,
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
    const iosDetails = DarwinNotificationDetails(presentSound: true);
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.cancel(notificationId);
    await _plugin.zonedSchedule(
      notificationId,
      exerciseName == null ? 'Descanso finalizado' : 'Listo: $exerciseName',
      nextSetNumber == null
          ? 'Vuelve al ejercicio'
          : 'Comienza el set $nextSetNumber.',
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

  static Future<void> cancelWarmUp({required int notificationId}) async {
    await cancelRest(notificationId: notificationId);
  }

  static Future<void> cancelAll() async {
    if (!_isInitialized) {
      return;
    }
    await _plugin.cancelAll();
  }

  static Future<void> scheduleWarmUpPhaseDone(
    int seconds, {
    required String title,
    required String body,
    required int notificationId,
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
    const iosDetails = DarwinNotificationDetails(presentSound: true);
    await _plugin.cancel(notificationId);
    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
