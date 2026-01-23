// features/settings/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Import your new Manager

// 2. Import the Warning Card (Adjust path if needed based on where you created it)
import '../../../services/notification_service.dart';
import 'battery_warning_card.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  // Singleton instance of the new Engine
  final NotificationManager _notificationManager = NotificationManager();

  // Unique IDs for the three daily alarms
  static const int _morningId = 1;
  static const int _afternoonId = 2;
  static const int _eveningId = 3;

  bool _isLoading = true;
  bool _notificationsEnabled = false;

  // Default Times
  TimeOfDay _morningTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _afternoonTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 1. Load saved preferences from disk
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (mounted) {
        setState(() {
          _notificationsEnabled =
              prefs.getBool('notifications_enabled') ?? false;

          // Load saved hours/minutes, fallback to defaults if null
          _morningTime = TimeOfDay(
            hour: prefs.getInt('morning_hour') ?? 9,
            minute: prefs.getInt('morning_minute') ?? 0,
          );

          _afternoonTime = TimeOfDay(
            hour: prefs.getInt('afternoon_hour') ?? 13,
            minute: prefs.getInt('afternoon_minute') ?? 0,
          );

          _eveningTime = TimeOfDay(
            hour: prefs.getInt('evening_hour') ?? 18,
            minute: prefs.getInt('evening_minute') ?? 0,
          );

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 2. Toggle Master Switch
  Future<void> _toggleNotifications(bool enabled) async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();

      if (enabled) {
        // A. Permission Check (Android 13/14)
        await _notificationManager.requestPermissions();

        // B. Schedule All Alarms
        await _scheduleAll();
      } else {
        // C. Cancel All Alarms
        await _notificationManager.cancelAlarm(_morningId);
        await _notificationManager.cancelAlarm(_afternoonId);
        await _notificationManager.cancelAlarm(_eveningId);
      }

      // Save the switch state
      await prefs.setBool('notifications_enabled', enabled);

      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Reminders enabled' : 'Reminders disabled'),
            backgroundColor: enabled ? Colors.green : Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to update: $e');
      }
    }
  }

  /// Helper: Schedules all 3 slots based on current TimeOfDay variables
  Future<void> _scheduleAll() async {
    await _scheduleSingle(_morningId, 'Morning Hydration', _morningTime);
    await _scheduleSingle(_afternoonId, 'Afternoon Hydration', _afternoonTime);
    await _scheduleSingle(_eveningId, 'Evening Hydration', _eveningTime);
  }

  /// Helper: Schedules a single alarm (adjusts for tomorrow if time passed)
  Future<void> _scheduleSingle(int id, String title, TimeOfDay time) async {
    final now = DateTime.now();

    // Create a DateTime for today at the specific hour/minute
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If that time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationManager.scheduleAggressiveAlarm(
      id: id,
      title: title,
      body: "Time to drink water!",
      scheduledTime: scheduledDate,
    );
  }

  /// 3. Update a Specific Time Slot
  Future<void> _updateNotificationTime(
    TimeOfDay newTime,
    String timeType,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int id = 0;
      String title = "";

      // Update Local State & Save to Disk
      setState(() {
        switch (timeType) {
          case 'morning':
            _morningTime = newTime;
            id = _morningId;
            title = 'Morning Hydration';
            prefs.setInt('morning_hour', newTime.hour);
            prefs.setInt('morning_minute', newTime.minute);
            break;
          case 'afternoon':
            _afternoonTime = newTime;
            id = _afternoonId;
            title = 'Afternoon Hydration';
            prefs.setInt('afternoon_hour', newTime.hour);
            prefs.setInt('afternoon_minute', newTime.minute);
            break;
          case 'evening':
            _eveningTime = newTime;
            id = _eveningId;
            title = 'Evening Hydration';
            prefs.setInt('evening_hour', newTime.hour);
            prefs.setInt('evening_minute', newTime.minute);
            break;
        }
      });

      // If notifications are active, update the actual alarm immediately
      if (_notificationsEnabled) {
        // Cancel old one first (optional, but cleaner)
        await _notificationManager.cancelAlarm(id);
        // Schedule new one
        await _scheduleSingle(id, title, newTime);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder time updated'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Failed to update time: $e');
    }
  }

  // --- UI Helpers ---

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay initialTime,
    String timeType,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF5DADE2)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await _updateNotificationTime(picked, timeType);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // --- 1. THE BATTERY WARNING CARD ---
          // This will automatically show/hide based on device manufacturer
          const BatteryWarningCard(),
          const SizedBox(height: 16),
          // -----------------------------------

          // --- 2. Master Toggle ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enable Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Receive hydration reminders',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: const Color(0xFF5DADE2),
                ),
              ],
            ),
          ),

          // --- 3. Time Pickers (Conditional) ---
          if (_notificationsEnabled) ...[
            const SizedBox(height: 32),

            // Section Header
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'REMINDER TIMES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Morning
            _buildTimeCard(
              icon: Icons.wb_sunny_outlined,
              iconColor: Colors.orange,
              label: 'Morning',
              time: _morningTime,
              onTap: () => _selectTime(context, _morningTime, 'morning'),
            ),

            const SizedBox(height: 12),

            // Afternoon
            _buildTimeCard(
              icon: Icons.wb_cloudy_outlined,
              iconColor: Colors.blue,
              label: 'Afternoon',
              time: _afternoonTime,
              onTap: () => _selectTime(context, _afternoonTime, 'afternoon'),
            ),

            const SizedBox(height: 12),

            // Evening
            _buildTimeCard(
              icon: Icons.nightlight_outlined,
              iconColor: Colors.indigo,
              label: 'Evening',
              time: _eveningTime,
              onTap: () => _selectTime(context, _eveningTime, 'evening'),
            ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You\'ll receive gentle reminders at these times to stay hydrated throughout the day.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              _formatTime(time),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5DADE2),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.access_time, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
