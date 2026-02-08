import 'package:bluedrop_v2/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_service.dart';
import 'theme.dart';
import 'router.dart';

// Diagnostic tool to check if alarms are actually scheduled
Future<void> diagnoseDangerousAlarms() async {
  final List<PendingNotificationRequest> pending = await NotificationManager()
      .plugin
      .pendingNotificationRequests();

  print("🔍 --- DIAGNOSTIC REPORT ---");
  if (pending.isEmpty) {
    print("   [ ] No alarms scheduled. System is idle.");
  } else {
    print("   [!] Found ${pending.length} ACTIVE alarms:");
    for (var p in pending) {
      print("       - ID: ${p.id} | Title: ${p.title} | Body: ${p.body}");
    }
  }
  print("---------------------------");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. FIREBASE
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyD3bk305sdAiQsrycp4_rQbOaW4y9ipnrQ",
            authDomain: "water-3db9c.firebaseapp.com",
            projectId: "water-3db9c",
            storageBucket: "water-3db9c.firebasestorage.app",
            messagingSenderId: "236007535708",
            appId: "1:236007535708:web:499a65eb84b519ddc7e299",
            measurementId: "G-JFJVJCJDFV",
          )
        : null,
  );
  print('✅ Firebase initialized');

  // 2. DATABASE
  print('🗄️ Initializing Database...');
  await DatabaseService().initialize(
    boxes: [
      'user_profile',
      'waterLogs',
      'reminders',
      'challenges',
      'user_containers',
    ],
  );
  // Optional: Only inject if empty to avoid duplicates
  // await SeedData.injectDummyChallenges();

  print('🚀 Starting app...');

  // --- 3. NOTIFICATION ENGINE (The Fix) ---
  print('🔔 Initializing Notification Engine...');

  // Initialize and create the NEW channel
  await NotificationManager().init();

  print('🧪 Testing immediate notification...');

  // CRITICAL FIX: Use the NEW Channel ID ('bluedrop_silent_v3')
  // Using the old ID ('critical_channel_id') would be silent/broken.
  await NotificationManager().plugin.show(
    777, // Test ID
    "✅ System Online",
    "This notification confirms the new channel is active.",
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'bluedrop_silent_v3', // <--- MUST MATCH NotificationManager.dart
        'High Priority Alerts', // <--- MUST MATCH NotificationManager.dart
        channelDescription: 'Visual alerts for medication',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true, // Test the lockscreen wakeup
        playSound: false, // As per your request (visual only)
        enableVibration: true,
      ),
    ),
  );
  print('✅ Immediate notification dispatched');

  // Run diagnostics to see if any old alarms are hanging around
  await diagnoseDangerousAlarms();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'BlueDrop',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}
