// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _db = DatabaseService();

  bool _isInitialized = false;

  // Notification IDs for different reminder times
  static const int morningNotificationId = 1;
  static const int afternoonNotificationId = 2;
  static const int eveningNotificationId = 3;

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initSettings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      print('✅ Notification service initialized');

      // Load and schedule notifications if enabled
      await _loadAndScheduleNotifications();
    } catch (e) {
      print('❌ Notification initialization failed: $e');
    }
  }

  // ============================================
  // NOTIFICATION SCHEDULING
  // ============================================

  /// Load settings from database and schedule notifications
  Future<void> _loadAndScheduleNotifications() async {
    try {
      final profile = await _db.getProfile();

      if (profile == null) return;

      final enabled = profile['notificationsEnabled'] ?? false;

      if (!enabled) {
        await cancelAllNotifications();
        return;
      }

      // Parse times
      final morningTime = _parseTime(profile['morningTime'] ?? '9:0');
      final afternoonTime = _parseTime(profile['afternoonTime'] ?? '13:0');
      final eveningTime = _parseTime(profile['eveningTime'] ?? '18:0');

      // Schedule notifications
      await _scheduleDailyNotification(
        id: morningNotificationId,
        hour: morningTime.hour,
        minute: morningTime.minute,
        title: '🌅 Morning Hydration Reminder',
        body: 'Start your day right! Time to drink some water.',
      );

      await _scheduleDailyNotification(
        id: afternoonNotificationId,
        hour: afternoonTime.hour,
        minute: afternoonTime.minute,
        title: '☀️ Afternoon Check-in',
        body: 'Keep up the good work! Don\'t forget to hydrate.',
      );

      await _scheduleDailyNotification(
        id: eveningNotificationId,
        hour: eveningTime.hour,
        minute: eveningTime.minute,
        title: '🌙 Evening Reminder',
        body: 'Almost done for the day! Time for some water.',
      );

      print('✅ Notifications scheduled');
    } catch (e) {
      print('❌ Failed to load and schedule notifications: $e');
    }
  }

  /// Schedule a daily notification at specific time
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_reminders',
            'Hydration Reminders',
            channelDescription: 'Daily reminders to drink water',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );

      print('✅ Scheduled notification $id for $hour:$minute');
    } catch (e) {
      print('❌ Failed to schedule notification $id: $e');
    }
  }

  // ============================================
  // PUBLIC METHODS
  // ============================================

  /// Enable notifications and schedule them
  Future<void> enableNotifications({
    required int morningHour,
    required int morningMinute,
    required int afternoonHour,
    required int afternoonMinute,
    required int eveningHour,
    required int eveningMinute,
  }) async {
    try {
      // Request permission (Android 13+)
      await _requestPermission();

      // Save settings to database
      await _db.updateProfile({
        'notificationsEnabled': true,
        'morningTime': '$morningHour:$morningMinute',
        'afternoonTime': '$afternoonHour:$afternoonMinute',
        'eveningTime': '$eveningHour:$eveningMinute',
      });

      // Schedule notifications
      await _scheduleDailyNotification(
        id: morningNotificationId,
        hour: morningHour,
        minute: morningMinute,
        title: '🌅 Morning Hydration Reminder',
        body: 'Start your day right! Time to drink some water.',
      );

      await _scheduleDailyNotification(
        id: afternoonNotificationId,
        hour: afternoonHour,
        minute: afternoonMinute,
        title: '☀️ Afternoon Check-in',
        body: 'Keep up the good work! Don\'t forget to hydrate.',
      );

      await _scheduleDailyNotification(
        id: eveningNotificationId,
        hour: eveningHour,
        minute: eveningMinute,
        title: '🌙 Evening Reminder',
        body: 'Almost done for the day! Time for some water.',
      );

      print('✅ Notifications enabled and scheduled');
    } catch (e) {
      print('❌ Failed to enable notifications: $e');
      rethrow;
    }
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    try {
      await cancelAllNotifications();

      await _db.updateProfile({'notificationsEnabled': false});

      print('✅ Notifications disabled');
    } catch (e) {
      print('❌ Failed to disable notifications: $e');
      rethrow;
    }
  }

  /// Update notification times
  Future<void> updateNotificationTimes({
    required int morningHour,
    required int morningMinute,
    required int afternoonHour,
    required int afternoonMinute,
    required int eveningHour,
    required int eveningMinute,
  }) async {
    try {
      // Save to database
      await _db.updateProfile({
        'morningTime': '$morningHour:$morningMinute',
        'afternoonTime': '$afternoonHour:$afternoonMinute',
        'eveningTime': '$eveningHour:$eveningMinute',
      });

      // Reschedule notifications
      await _scheduleDailyNotification(
        id: morningNotificationId,
        hour: morningHour,
        minute: morningMinute,
        title: '🌅 Morning Hydration Reminder',
        body: 'Start your day right! Time to drink some water.',
      );

      await _scheduleDailyNotification(
        id: afternoonNotificationId,
        hour: afternoonHour,
        minute: afternoonMinute,
        title: '☀️ Afternoon Check-in',
        body: 'Keep up the good work! Don\'t forget to hydrate.',
      );

      await _scheduleDailyNotification(
        id: eveningNotificationId,
        hour: eveningHour,
        minute: eveningMinute,
        title: '🌙 Evening Reminder',
        body: 'Almost done for the day! Time for some water.',
      );

      print('✅ Notification times updated');
    } catch (e) {
      print('❌ Failed to update notification times: $e');
      rethrow;
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('✅ All notifications cancelled');
    } catch (e) {
      print('❌ Failed to cancel notifications: $e');
    }
  }

  /// Get notification settings from database
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final profile = await _db.getProfile();

      return {
        'enabled': profile?['notificationsEnabled'] ?? false,
        'morningTime': _parseTime(profile?['morningTime'] ?? '9:0'),
        'afternoonTime': _parseTime(profile?['afternoonTime'] ?? '13:0'),
        'eveningTime': _parseTime(profile?['eveningTime'] ?? '18:0'),
      };
    } catch (e) {
      print('❌ Failed to get notification settings: $e');
      return {
        'enabled': false,
        'morningTime': _TimeOfDay(9, 0),
        'afternoonTime': _TimeOfDay(13, 0),
        'eveningTime': _TimeOfDay(18, 0),
      };
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  /// Request notification permission (Android 13+)
  Future<void> _requestPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      print('⚠️ Permission request not available: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate to water logging screen or home
  }

  /// Parse time string to TimeOfDay-like object
  _TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return _TimeOfDay(int.parse(parts[0]), int.parse(parts[1]));
  }
}

// Simple TimeOfDay replacement for service
class _TimeOfDay {
  final int hour;
  final int minute;

  _TimeOfDay(this.hour, this.minute);
}
