import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class AndroidNotificationEngine {
  // Singleton pattern
  static final AndroidNotificationEngine _instance =
      AndroidNotificationEngine._internal();
  factory AndroidNotificationEngine() => _instance;

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidNotificationEngine._internal()
    : _plugin = FlutterLocalNotificationsPlugin();

  /// **1. Initialization Sequence**
  Future<void> initialize() async {
    try {
      print('🚀 === INITIALIZATION START ===');

      print('🌍 Initializing timezones...');
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings);

      print('🔧 Initializing plugin...');
      await _plugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('🔔 Notification Tapped! Payload: ${response.payload}');
        },
      );

      await _createNotificationChannel();
      print('✅ Engine Initialized');
    } catch (e, stackTrace) {
      print('💥 INITIALIZATION FAILED: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// **2. Create Channel (High Importance)**
  Future<void> _createNotificationChannel() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation == null) return;

    const AndroidNotificationChannel studyChannel = AndroidNotificationChannel(
      'study_reminders_v1',
      'Study Reminders',
      description: 'Critical alerts for exam preparation',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidImplementation.createNotificationChannel(studyChannel);
  }

  /// **3. Permissions & Scheduling**
  Future<void> requestPermissionsAndSchedule() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    // Battery Optimization "Vaccine" (The Tecno Fix)
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      print('⚠️ Requesting Battery Exemption...');
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  /// **Generic Targeted Scheduling**
  /// Accepts explicit data and time, relying on the Service layer for logic.
  Future<void> scheduleTargetedNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_reminders_v1', // Reusing your existing high-importance channel
            'Study Reminders',
            importance: Importance.max,
            priority: Priority.max,
            enableLights: true,
            playSound: true,
            fullScreenIntent: false,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('✅ Scheduled ID: $id at $scheduledDate');
    } catch (e) {
      print('❌ Failed to schedule ID $id: $e');
    }
  }

  /// **Explicit Cancellation**
  /// Cancels a specific notification ID from the OS queue.
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id: id);
      print('🗑️ Cancelled ID: $id');
    } catch (e) {
      print('❌ Failed to cancel ID $id: $e');
    }
  }

  /// **Master Reset (Optional but recommended)**
  /// Clears the entire queue.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    print('🧹 All notifications cleared');
  }

  /// **5. Instant Notification (Smoke Test)**
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    // 🚨 CRITICAL FIX: All parameters are now NAMED here too
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_reminders_v1',
          'Study Reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: false,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      payload: payload,
    );
  }
}
