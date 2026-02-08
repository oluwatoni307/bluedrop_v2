import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';
import 'router.dart';

// Diagnostic tool to check if alarms are actually scheduled
// Updated to instantiate a plugin instance directly for querying
Future<void> diagnoseDangerousAlarms() async {
  final List<PendingNotificationRequest> pending =
      await FlutterLocalNotificationsPlugin().pendingNotificationRequests();

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

  // --- 3. NOTIFICATION ENGINE (UPDATED) ---
  print('🔔 Initializing Notification Engine...');

  // A. Initialize & Create Channels (API 26+)
  await AndroidNotificationEngine().initialize();

  // B. Check Permissions (This is a good place to log status, but request usually happens on UI)
  // For the purpose of this smoke test, we log the status.
  // Note: We don't await the request here to avoid blocking startup with a dialog.
  print('🔔 Notification Engine Ready.');

  print('🧪 Testing immediate notification...');

  // C. Test Notification using the NEW Engine
  // This uses the 'study_reminders_v1' channel we defined in the engine.
  await AndroidNotificationEngine().showInstantNotification(
    id: 777,
    title: "✅ System Online",
    body: "The Android Notification Engine is active.",
    payload: "test_payload",
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
