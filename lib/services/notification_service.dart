import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const String _storageKey = 'scheduled_alarms_v1';

  /// 1. INITIALIZE
  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification Clicked: ${details.payload}");
      },
    );

    await _createCriticalChannel();
  }

  /// 2. REQUEST PERMISSIONS
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.requestNotificationsPermission();

      final bool? granted = await androidPlugin?.requestExactAlarmsPermission();
      if (granted == false) {
        debugPrint("Exact Alarm permission denied.");
      }
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// 3. SCHEDULE (Aggressive Mode)
  Future<void> scheduleAggressiveAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _saveAlarmToDisk(id, title, body, scheduledTime);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'critical_channel_id',
          'Critical Reminders',
          channelDescription: 'Used for important medical reminders',
          importance: Importance.max,
          priority: Priority.high,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      // ONLY this parameter is needed now
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  /// 4. RESTORE (Boot Recovery)
  Future<void> restoreScheduledAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedString = prefs.getString(_storageKey);

    if (storedString == null) return;

    List<dynamic> alarms = jsonDecode(storedString);
    final now = DateTime.now();

    for (var alarm in alarms) {
      final DateTime scheduledTime = DateTime.parse(alarm['time']);

      if (scheduledTime.isAfter(now)) {
        await _plugin.zonedSchedule(
          alarm['id'],
          alarm['title'],
          alarm['body'],
          tz.TZDateTime.from(scheduledTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'critical_channel_id',
              'Critical Reminders',
              importance: Importance.max,
              priority: Priority.high,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              category: AndroidNotificationCategory.alarm,
              fullScreenIntent: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
        );
      }
    }
  }

  /// 5. CANCEL
  Future<void> cancelAlarm(int id) async {
    await _plugin.cancel(id);
    await _removeAlarmFromDisk(id);
  }

  // --- PRIVATE HELPERS ---

  Future<void> _createCriticalChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'critical_channel_id',
      'Critical Reminders',
      description: 'Used for important medical reminders',
      importance: Importance.max,
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _saveAlarmToDisk(
    int id,
    String title,
    String body,
    DateTime time,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> currentAlarms = await _getStoredAlarms();
    currentAlarms.removeWhere((e) => e['id'] == id);
    currentAlarms.add({
      'id': id,
      'title': title,
      'body': body,
      'time': time.toIso8601String(),
    });
    await prefs.setString(_storageKey, jsonEncode(currentAlarms));
  }

  Future<void> _removeAlarmFromDisk(int id) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> currentAlarms = await _getStoredAlarms();
    currentAlarms.removeWhere((e) => e['id'] == id);
    await prefs.setString(_storageKey, jsonEncode(currentAlarms));
  }

  Future<List<Map<String, dynamic>>> _getStoredAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedString = prefs.getString(_storageKey);
    return storedString == null
        ? []
        : List<Map<String, dynamic>>.from(jsonDecode(storedString));
  }
}
