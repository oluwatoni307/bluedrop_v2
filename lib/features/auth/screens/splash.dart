import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz; // REQUIRED: For Timezones

// --- SERVICES ---
// Adjust these paths to match your folder structure exactly
import '../../../../services/database_service.dart';
// import '../../../../services/notification_service.dart';
import '../../../../services/notification_engine.dart';
import '../../../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitialized;

  const SplashScreen({super.key, required this.onInitialized});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  /// Runs all the heavy startup logic
  Future<void> _bootstrapApp() async {
    print('🚀 SPLASH: Starting App Initialization...');

    // 1. DATABASE
    print('🗄️ SPLASH: Initializing Database...');
    await DatabaseService().initialize(
      boxes: [
        'user_profile',
        'waterLogs',
        'reminders',
        'challenges',
        'user_containers',
      ],
    );

    // 2. TIMEZONES (CRITICAL FIX)
    // Without this, the NotificationService will crash when scheduling
    print('🌍 SPLASH: Initializing Timezones...');
    tz.initializeTimeZones();

    // 3. NOTIFICATION ENGINE
    print('🔔 SPLASH: Initializing Notification Engine...');
    await AndroidNotificationEngine().initialize();
    await AndroidNotificationEngine().requestPermissionsAndSchedule();

    // // 4. NOTIFICATION LOGIC (CRITICAL FIX)
    // // A. Seed Data: Ensures we have default settings if this is the first run
    // await NotificationService().initializeDefaultData();

    // // B. Sync: This checks the "4-Day Rule" and extends alarms if needed
    // print('🔄 SPLASH: Syncing Notification Schedule...');
    // await NotificationService().sync(hardSync: true);
    // print('✅ SPLASH: Initialization Complete.');
    // 4. BACKGROUND SERVER WARM-UP (The "Ping")
    // Note: We do NOT use 'await' here.
    // This allows the app to move to the Dashboard while the server wakes up.
    print('📡 SPLASH: Firing background server ping...');
    ApiService().checkServerHealth().then((isAlive) {
      if (isAlive) {
        print('🟢 SPLASH: Server is awake and ready.');
      }
    });

    // 5. TELL THE ROUTER WE ARE DONE
    if (mounted) {
      widget.onInitialized();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.water_drop, size: 72, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text(
              'BlueDrop',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
