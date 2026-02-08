import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class AndroidNotificationEngine {
  // Singleton pattern
  static final AndroidNotificationEngine _instance =
      AndroidNotificationEngine._internal();
  factory AndroidNotificationEngine() => _instance;

  final FlutterLocalNotificationsPlugin _plugin;

  // Private constructor
  AndroidNotificationEngine._internal()
    : _plugin = FlutterLocalNotificationsPlugin();

  /// **1. Initialization Sequence**
  /// This must be called in `main()` before `runApp()`.
  /// It sets up the icon, initializes the plugin, and registers channels.
  Future<void> initialize() async {
    // SECURITY: Ensure the icon exists in 'android/app/src/main/res/drawable'
    // If '@mipmap/ic_launcher' is missing, the app will crash immediately.
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // This is the entry point for deep linking (Phase 4)
        debugPrint('Notification Tapped. Payload: ${response.payload}');
      },
    );

    // CRITICAL: Android 8.0+ requires channels to be created before any notification is shown.
    await _createNotificationChannels();
  }

  /// **2. Channel Registration (API 26+)**
  /// Defines the "pipelines" through which notifications flow.
  Future<void> _createNotificationChannels() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Safety check: ensure we are actually on Android
    if (androidImplementation == null) return;

    // Channel A: High Importance (Heads-up Display, Sound)
    // Use Case: Study reminders, Exam alerts.
    const AndroidNotificationChannel studyChannel = AndroidNotificationChannel(
      'study_reminders_v1', // ID: Change this if you update channel settings later
      'Study Reminders', // Visible Name
      description: 'Critical alerts for exam preparation',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Channel B: Low Importance (Silent, Minimized)
    // Use Case: Progress updates, Background sync.
    const AndroidNotificationChannel backgroundChannel =
        AndroidNotificationChannel(
          'background_sync_v1',
          'System Updates',
          description: 'Silent background activity',
          importance: Importance.low, // No sound, no visual interruption
          playSound: false,
          enableVibration: false,
        );

    await androidImplementation.createNotificationChannel(studyChannel);
    await androidImplementation.createNotificationChannel(backgroundChannel);
  }

  /// **3. Permission Request (API 33+)**
  /// Call this when the user enables a feature (e.g., toggles "Remind Me").
  /// Returns [true] if granted.
  Future<bool> requestPermissions() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation == null) return false;

    // Requests the 'android.permission.POST_NOTIFICATIONS' permission.
    final bool? granted = await androidImplementation
        .requestNotificationsPermission();

    return granted ?? false;
  }

  /// **4. Check Exact Alarm Permission (API 34+)**
  /// Google restricts 'SCHEDULE_EXACT_ALARM'. Use this to check if we can
  /// schedule precise timers. If false, fallback to inexact scheduling.
  Future<bool> checkExactAlarmPermission() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // If the method is not available (older Android), we assume true/supported.
    return await androidImplementation?.requestExactAlarmsPermission() ?? true;
  }

  /// **5. Instant Notification (Smoke Test)**
  /// Use this to verify the 'study_reminders' channel works.
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_reminders_v1', // MUST match the ID in _createNotificationChannels
          'Study Reminders',
          channelDescription: 'Critical alerts for exam preparation',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
      ),
      payload: payload,
    );
  }
}
