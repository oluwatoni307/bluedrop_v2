// features/settings/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  bool _notificationsEnabled = false;
  TimeOfDay _morningTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _afternoonTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _notificationService.getNotificationSettings();

      if (mounted) {
        setState(() {
          _notificationsEnabled = settings['enabled'] ?? false;

          final morning = settings['morningTime'];
          _morningTime = TimeOfDay(hour: morning.hour, minute: morning.minute);

          final afternoon = settings['afternoonTime'];
          _afternoonTime = TimeOfDay(
            hour: afternoon.hour,
            minute: afternoon.minute,
          );

          final evening = settings['eveningTime'];
          _eveningTime = TimeOfDay(hour: evening.hour, minute: evening.minute);

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    try {
      setState(() => _isLoading = true);

      if (enabled) {
        await _notificationService.enableNotifications(
          morningHour: _morningTime.hour,
          morningMinute: _morningTime.minute,
          afternoonHour: _afternoonTime.hour,
          afternoonMinute: _afternoonTime.minute,
          eveningHour: _eveningTime.hour,
          eveningMinute: _eveningTime.minute,
        );
      } else {
        await _notificationService.disableNotifications();
      }

      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled ? 'Notifications enabled' : 'Notifications disabled',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notifications: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateNotificationTime(
    TimeOfDay newTime,
    String timeType,
  ) async {
    try {
      // Update local state
      setState(() {
        switch (timeType) {
          case 'morning':
            _morningTime = newTime;
            break;
          case 'afternoon':
            _afternoonTime = newTime;
            break;
          case 'evening':
            _eveningTime = newTime;
            break;
        }
      });

      // Update service
      await _notificationService.updateNotificationTimes(
        morningHour: _morningTime.hour,
        morningMinute: _morningTime.minute,
        afternoonHour: _afternoonTime.hour,
        afternoonMinute: _afternoonTime.minute,
        eveningHour: _eveningTime.hour,
        eveningMinute: _eveningTime.minute,
      );

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update time: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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
          // Enable/Disable Toggle
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

            // Morning Reminder
            _buildTimeCard(
              icon: Icons.wb_sunny_outlined,
              iconColor: Colors.orange,
              label: 'Morning',
              time: _morningTime,
              onTap: () => _selectTime(context, _morningTime, 'morning'),
            ),

            const SizedBox(height: 12),

            // Afternoon Reminder
            _buildTimeCard(
              icon: Icons.wb_cloudy_outlined,
              iconColor: Colors.blue,
              label: 'Afternoon',
              time: _afternoonTime,
              onTap: () => _selectTime(context, _afternoonTime, 'afternoon'),
            ),

            const SizedBox(height: 12),

            // Evening Reminder
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
