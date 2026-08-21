import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'theme.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔥 MAIN: Initializing Firebase...');
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

  // Notifications are optional; a platform/plugin failure must not prevent
  // the application from launching.
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance.subscribeToTopic('all_users');
  } catch (e) {
    print('⚠️ MAIN: Notification setup skipped: $e');
  }

  print('🚀 MAIN: Firebase Ready. Launching App...');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

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
