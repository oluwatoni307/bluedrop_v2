import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> _bootstrapApp() async {
    print('🚀 SPLASH: Starting App Initialization...');

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

    print('🌍 SPLASH: Initializing Timezones...');
    tz.initializeTimeZones();

    print('🔔 SPLASH: Initializing Notification Engine...');
    await AndroidNotificationEngine().initialize();
    await AndroidNotificationEngine().requestPermissionsAndSchedule();

    print('📡 SPLASH: Firing background server ping...');
    ApiService().checkServerHealth().then((isAlive) {
      if (isAlive) print('🟢 SPLASH: Server is awake and ready.');
    });

    print('✅ SPLASH: Initialization Complete.');

    // Unlock the router gate then navigate — auth redirect handles the rest
    if (mounted) {
      widget.onInitialized();
      context.go('/'); // ← This is the fix
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
