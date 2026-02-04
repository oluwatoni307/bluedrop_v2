import 'package:bluedrop_v2/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/hub/data/seed_data.dart';
import 'services/database_service.dart';
import 'theme.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔥 Initializing Firebase...');

  FirebaseOptions? firebaseOptions;

  if (kIsWeb) {
    firebaseOptions = const FirebaseOptions(
      apiKey: "AIzaSyD3bk305sdAiQsrycp4_rQbOaW4y9ipnrQ",
      authDomain: "water-3db9c.firebaseapp.com",
      projectId: "water-3db9c",
      storageBucket: "water-3db9c.firebasestorage.app",
      messagingSenderId: "236007535708",
      appId: "1:236007535708:web:499a65eb84b519ddc7e299",
      measurementId: "G-JFJVJCJDFV",
    );
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    firebaseOptions = const FirebaseOptions(
      apiKey: "AIzaSyA-tby7DGCIhXGOWNo5yckAwU-wQG-yxEY", // From your JSON
      appId: "1:236007535708:android:73515d86fb209659c7e299", // From your JSON
      messagingSenderId: "236007535708", // From your JSON project_number
      projectId: "water-3db9c", // From your JSON
      storageBucket: "water-3db9c.firebasestorage.app",
    );
  }

  await Firebase.initializeApp(options: firebaseOptions);
  print('✅ Firebase initialized');
  print('✅ Firebase initialized');

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
  await SeedData.injectDummyChallenges();

  print('🚀 Starting app...');

  // --- NEW NOTIFICATION LOGIC START ---
  print('🔔 Initializing Notification Engine...');
  // 1. Initialize the Engine (Channels, Permissions Config)
  await NotificationManager().init();

  // 2. Restore Scheduled Alarms from DB
  print('♻️ Restoring Scheduled Alarms...');
  await NotificationManager().restoreScheduledAlarms();
  await scheduleTestAlarms();
  // --- NEW NOTIFICATION LOGIC END ---

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
