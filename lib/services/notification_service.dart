import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationManager {
  // Singleton pattern
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Use a fresh channel ID to clear any previous "broken" settings on the device
  static const String _channelId = 'bluedrop_silent_v3';
  static const String _channelName = 'High Priority Alerts';
  static const String _storageKey = 'scheduled_alarms_v2';

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// 1. ROBUST INITIALIZATION
  Future<void> init() async {
    // A. Timezone Setup (Crucial for scheduled alarms)
    try {
      tz.initializeTimeZones();
      // Attempt to set a known safe location if local fails,
      // but usually local is fine if initialized.
      // tz.setLocalLocation(tz.getLocation('Africa/Lagos')); // Optional: Force location
    } catch (e) {
      debugPrint("⚠️ Timezone Error: $e");
    }

    // B. Platform Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("🔔 Notification Clicked: ${details.payload}");
      },
    );

    // C. Create the Channel (Immutable once created!)
    await _createCriticalChannel();

    // D. Request Permissions
    await requestPermissions();
  }

  /// 2. PERMISSION REQUESTS (Android 13/14 Compliant)
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // A. Notification Permission (Android 13+)
      await androidPlugin?.requestNotificationsPermission();

      // B. Exact Alarm Permission (Android 12+)
      // We check strict status first
      await androidPlugin?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// 3. SMART SCHEDULE (The Fix for `pi_cancelled`)
  Future<void> scheduleAggressiveAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // SAFETY CHECK: Don't schedule in the past
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("❌ Ignored schedule request for past time: $tzTime");
      return;
    }

    // DUPLICATE CHECK: Don't re-schedule if it's already there (Prevents pi_cancelled)
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();

    final bool alreadyExists = pending.any((p) => p.id == id);

    // If it exists, we cancel it first explicitly to be clean,
    // OR we can skip it. For updating data, we usually cancel first.
    if (alreadyExists) {
      debugPrint("🔄 Updating existing alarm #$id");
      await _plugin.cancel(id);
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Visual alerts for medication',

            // MAXIMUM PRIORITY SETTINGS
            importance: Importance.max,
            priority: Priority.max,

            // SCREEN WAKEUP SETTINGS
            fullScreenIntent: true, // Shows over lockscreen
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.alarm,

            // VISUALS ONLY (No Sound requested)
            playSound: false,
            enableVibration: true,

            // PERSISTENCE
            ongoing: false,
            autoCancel: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentList: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        // AGGRESSIVE TIMING MODE
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );

      debugPrint("✅ Scheduled #$id for ${tzTime.toString()}");

      // Save to disk for UI restoration only (not for Logic restoration)
      await _saveAlarmToDisk(id, title, body, scheduledTime);
    } catch (e) {
      debugPrint("❌ CRITICAL FAILURE in Schedule: $e");
    }
  }

  /// 4. SAFE RESTORE (Does not loop-kill alarms)
  /// Only call this if you suspect the OS dropped alarms (rare)
  /// or to populate your UI list.
  Future<void> syncAlarms() async {
    debugPrint("📥 Syncing alarms...");
    // We trust the OS to keep the alarms via the BootReceiver.
    // We only use this to clean up our local disk storage if an alarm has passed.

    final prefs = await SharedPreferences.getInstance();
    final String? storedString = prefs.getString(_storageKey);
    if (storedString == null) return;

    List<dynamic> alarms = jsonDecode(storedString);
    List<Map<String, dynamic>> validAlarms = [];
    final now = DateTime.now();

    for (var alarm in alarms) {
      final DateTime scheduledTime = DateTime.parse(alarm['time']);
      if (scheduledTime.isAfter(now)) {
        validAlarms.add(alarm as Map<String, dynamic>);
        // We DO NOT call zonedSchedule here blindly.
        // We assume the BootReceiver handled it.
        // Only reschedule if pending list is empty? (Optional advanced logic)
      }
    }

    // Update disk to remove old/passed alarms
    await prefs.setString(_storageKey, jsonEncode(validAlarms));
  }

  Future<void> cancelAlarm(int id) async {
    await _plugin.cancel(id);
    await _removeAlarmFromDisk(id);
  }

  // --- INTERNAL HELPERS ---

  Future<void> _createCriticalChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Visual alerts for medication',
      importance: Importance.max, // MAX implies heads-up display
      playSound: false,
      enableVibration: true,
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
