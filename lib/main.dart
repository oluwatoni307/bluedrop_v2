import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/hub/data/seed_data.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  print('🗄️ Initializing Database...');
  await DatabaseService().initialize(
    boxes: ['user_profile', 'waterLogs', 'reminders', 'challenges'],
  );
  await SeedData.injectDummyChallenges();
  print('🚀 Starting app...');
  await dotenv.load(fileName: ".env");
  await NotificationService().initialize();

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
