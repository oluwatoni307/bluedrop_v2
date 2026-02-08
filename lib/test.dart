import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'services/notification_service.dart';

Future<void> diagnoseDangerousAlarms() async {
  final manager = NotificationManager();

  // Note: Since _plugin is private in your manager, you'll need to
  // add a getter to NotificationManager:
  // FlutterLocalNotificationsPlugin get plugin => _plugin;
  // If you can't add that, this diagnostic won't be able to "peek" inside.

  print("\n🔍 === DIAGNOSTIC CHECK ===\n");

  // 1. Check permissions
  final androidPlugin = manager.plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  final canSchedule = await androidPlugin?.canScheduleExactNotifications();
  print(
    "1️⃣ Exact alarm permission: ${canSchedule == true ? '✅ GRANTED' : '❌ DENIED'}",
  );

  // 2. Check channels
  final channels = await androidPlugin?.getNotificationChannels();
  final hasCritical =
      channels?.any((c) => c.id == 'critical_channel_id') ?? false;
  print("2️⃣ Critical channel exists: ${hasCritical ? '✅ YES' : '❌ NO'}");
  print("   All channels: ${channels?.map((c) => c.id).toList()}");

  // 3. Check timezone
  print("3️⃣ Timezone: ${tz.local.name}");

  // 4. Try to schedule immediate test (30 seconds)
  final testTime = DateTime.now().add(const Duration(seconds: 30));
  print(
    "\n⏰ Scheduling test alarm for: ${testTime.hour}:${testTime.minute}:${testTime.second}",
  );

  try {
    await manager.scheduleAggressiveAlarm(
      id: 999,
      title: "🚨 TEST ALARM",
      body: "If you see this, notifications work!",
      scheduledTime: testTime,
    );
    print("   Schedule call completed without error");
  } catch (e) {
    print("   ❌ Schedule call threw error: $e");
  }

  // 5. Verify it's pending
  await Future.delayed(const Duration(seconds: 2));
  final pending = await manager.plugin.pendingNotificationRequests();
  print("\n4️⃣ Total pending notifications: ${pending.length}");
  final testExists = pending.any((n) => n.id == 999);
  print("   Test alarm (ID 999) in queue: ${testExists ? '✅ YES' : '❌ NO'}");

  if (pending.isNotEmpty) {
    print("   Pending IDs: ${pending.map((n) => n.id).toList()}");
  }

  if (testExists) {
    print("\n✅ Setup looks good! Wait 30 seconds for notification...");
  } else {
    print("\n❌ PROBLEM: Alarm was NOT queued!");
  }

  print("\n=========================\n");
}
