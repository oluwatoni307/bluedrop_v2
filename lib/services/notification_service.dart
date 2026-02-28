// import 'package:hive/hive.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'notification_engine.dart'; // Ensure this path is correct

// // ==========================================
// // DATA MODEL (Internal Use)
// // ==========================================
// class NotificationRequest {
//   final int slotIndex;
//   final String title;
//   final String body;
//   final int hour;
//   final int minute;
//   final DateTime endDate;
//   final bool isActive;

//   NotificationRequest({
//     required this.slotIndex,
//     required this.title,
//     required this.body,
//     required this.hour,
//     required this.minute,
//     required this.endDate,
//     required this.isActive,
//   });
// }

// class NotificationService {
//   final AndroidNotificationEngine _engine = AndroidNotificationEngine();

//   // --- ID CONSTANTS ---
//   static const int _waterMorningBaseId = 100;
//   static const int _waterAfternoonBaseId = 150; // 🆕 2 PM Slot
//   static const int _waterEveningBaseId = 200;
//   static const int _extra1BaseId = 300;
//   static const int _extra2BaseId = 400;

//   // ==========================================
//   // 1. HIVE PERSISTENCE
//   // ==========================================

//   /// READ: Fetches the config map.
//   Map<dynamic, dynamic> get notificationData {
//     if (!Hive.isBoxOpen('reminders')) {
//       print("⚠️ Error: 'reminders' box is not open!");
//       return {};
//     }
//     return Hive.box('reminders').get('notification_data', defaultValue: {});
//   }

//   /// WRITE: Saves the map.
//   Future<void> _saveData(Map<dynamic, dynamic> data) async {
//     final box = Hive.box('reminders');
//     await box.put('notification_data', data);
//     print("💾 Notification Data Saved.");
//   }

//   /// SEED: Initializes DEFAULT settings.
//   Future<void> initializeDefaultData() async {
//     final box = Hive.box('reminders');

//     if (!box.containsKey('notification_data')) {
//       print("🌱 Seeding default notification data...");

//       final Map<String, dynamic> defaultData = {
//         'data': DateTime.now(), // Start Date
//         // Water Configuration
//         'waterchallenge': {
//           'active': false, // Challenge Mode is OFF
//           'reminders_enabled': true, // Daily Nudges are ON
//           'title': 'Hydration Time! 💧',
//           'body': 'Time to drink water.',
//           'end_date': DateTime.now().add(const Duration(days: 30)),
//         },

//         // Side Challenge Placeholders (Inactive)
//         'sidechallenges': [
//           {
//             'active': false,
//             'slot_index': 1,
//             'title': 'Side Challenge 1',
//             'body': 'Description goes here.',
//             'hour': 10,
//             'minute': 0,
//             'end_date': DateTime.now().add(const Duration(days: 14)),
//           },
//           {
//             'active': false,
//             'slot_index': 2,
//             'title': 'Side Challenge 2',
//             'body': 'Description goes here.',
//             'hour': 16,
//             'minute': 0,
//             'end_date': DateTime.now().add(const Duration(days: 7)),
//           },
//         ],
//       };

//       await box.put('notification_data', defaultData);
//     }
//   }

//   // ==========================================
//   // 2. SYNC ENGINE (The Brain)
//   // ==========================================

//   Future<void> sync({bool hardSync = false}) async {
//     print("🔄 Starting Sync (Hard Sync: $hardSync)...");

//     var data = notificationData;
//     if (data.isEmpty) return;

//     DateTime lastScheduledDate = data['data'] as DateTime;
//     final DateTime now = DateTime.now();

//     // --- A. ROLLING WINDOW CHECK ---
//     // If schedule is older than 4 days, renew it for another week.
//     final int daysSinceLastSync = now.difference(lastScheduledDate).inDays;

//     if (daysSinceLastSync >= 4) {
//       print("⚠️ Schedule stale ($daysSinceLastSync days). Renewing...");

//       // Update Start Date to NOW
//       final Map<dynamic, dynamic> newData = Map.from(data);
//       newData['data'] = now;
//       await _saveData(newData);

//       // Refresh local vars
//       data = newData;
//       lastScheduledDate = now;
//       hardSync = true; // Force re-schedule
//     } else if (!hardSync) {
//       print(
//         "✅ Schedule healthy ($daysSinceLastSync days old). No sync needed.",
//       );
//       return;
//     }

//     // --- B. WATER SCHEDULE LOGIC ---
//     final Map<dynamic, dynamic> waterMap = data['waterchallenge'];

//     // Check if GLOBAL reminders are enabled (Default: True)
//     final bool areRemindersOn = waterMap['reminders_enabled'] ?? true;

//     if (areRemindersOn) {
//       // Logic: Use Challenge Text if Active, otherwise Default Text
//       String displayTitle = "Hydration Check 💧";
//       String displayBody = "Stay hydrated and healthy!";

//       if (waterMap['active'] == true) {
//         displayTitle = waterMap['title'] ?? displayTitle;
//         displayBody = waterMap['body'] ?? displayBody;
//       }

//       await _scheduleWaterReminders(
//         lastScheduledDate,
//         displayTitle,
//         displayBody,
//         waterMap['end_date'],
//       );
//     } else {
//       print("⏸️ All Water Reminders are disabled.");
//       await _cancelAllWater(); // Ensure they are dead
//     }

//     // --- C. SIDE CHALLENGES LOGIC ---
//     List<NotificationRequest> extraRequests = [];
//     if (data['sidechallenges'] != null) {
//       final List<dynamic> rawList = data['sidechallenges'];
//       extraRequests = rawList.map((item) {
//         return NotificationRequest(
//           slotIndex: item['slot_index'],
//           title: item['title'],
//           body: item['body'],
//           hour: item['hour'],
//           minute: item['minute'],
//           endDate: item['end_date'],
//           isActive: item['active'] ?? false,
//         );
//       }).toList();
//     }

//     await _scheduleExtraReminders(lastScheduledDate, extraRequests);
//     print("✨ Sync Complete.");
//   }

//   // ==========================================
//   // 3. SCHEDULING LOGIC (3x Daily)
//   // ==========================================

//   Future<void> _scheduleWaterReminders(
//     DateTime startDate,
//     String title,
//     String body,
//     DateTime waterEndDate,
//   ) async {
//     final DateTime now = DateTime.now();
//     // Safety check: Don't schedule if end date is passed
//     if (waterEndDate.isBefore(now)) return;

//     // Schedule for next 7 days
//     for (int day = 0; day <= 7; day++) {
//       // 1. Morning (9:00 AM)
//       final tz.TZDateTime morningDate = _constructDateTime(
//         startDate,
//         day,
//         9,
//         0,
//       );

//       // 2. Afternoon (2:00 PM) - 🆕 NEW
//       final tz.TZDateTime afternoonDate = _constructDateTime(
//         startDate,
//         day,
//         14,
//         0,
//       );

//       // 3. Evening (6:00 PM)
//       final tz.TZDateTime eveningDate = _constructDateTime(
//         startDate,
//         day,
//         18,
//         0,
//       );

//       final List<({tz.TZDateTime date, int baseId})> slots = [
//         (date: morningDate, baseId: _waterMorningBaseId),
//         (date: afternoonDate, baseId: _waterAfternoonBaseId),
//         (date: eveningDate, baseId: _waterEveningBaseId),
//       ];

//       for (var slot in slots) {
//         // Only schedule if it's in the future AND before the challenge ends
//         if (slot.date.isAfter(now) && slot.date.isBefore(waterEndDate)) {
//           await _engine.scheduleTargetedNotification(
//             id: slot.baseId + day,
//             title: title,
//             body: body,
//             scheduledDate: slot.date,
//           );
//         }
//       }
//     }
//     print("✅ Scheduled Water Reminders (9am, 2pm, 6pm) for 7 days.");
//   }

//   Future<void> _scheduleExtraReminders(
//     DateTime startDate,
//     List<NotificationRequest> requests,
//   ) async {
//     final DateTime now = DateTime.now();

//     for (int day = 0; day <= 7; day++) {
//       for (final request in requests) {
//         if (!request.isActive) continue;

//         final tz.TZDateTime scheduledDate = _constructDateTime(
//           startDate,
//           day,
//           request.hour,
//           request.minute,
//         );

//         if (scheduledDate.isAfter(now) &&
//             scheduledDate.isBefore(request.endDate)) {
//           final int baseId = request.slotIndex == 1
//               ? _extra1BaseId
//               : _extra2BaseId;
//           await _engine.scheduleTargetedNotification(
//             id: baseId + day,
//             title: request.title,
//             body: request.body,
//             scheduledDate: scheduledDate,
//           );
//         }
//       }
//     }
//   }

//   // ==========================================
//   // 4. SETTERS (Public API)
//   // ==========================================

//   /// Toggle Global Reminders (On/Off)
//   Future<void> toggleReminders(bool isEnabled) async {
//     final Map<dynamic, dynamic> rootData = Map.from(notificationData);
//     final Map<dynamic, dynamic> waterData = Map.from(
//       rootData['waterchallenge'],
//     );

//     waterData['reminders_enabled'] = isEnabled;
//     rootData['waterchallenge'] = waterData;

//     await _saveData(rootData);
//     await sync(hardSync: true); // Force update
//   }

//   /// Activate a specific Challenge
//   Future<void> setWaterChallenge({
//     bool? isActive,
//     String? title,
//     String? body,
//     DateTime? endDate,
//   }) async {
//     final Map<dynamic, dynamic> rootData = Map.from(notificationData);
//     final Map<dynamic, dynamic> waterData = Map.from(
//       rootData['waterchallenge'],
//     );

//     if (isActive != null) waterData['active'] = isActive;
//     if (title != null) waterData['title'] = title;
//     if (body != null) waterData['body'] = body;
//     if (endDate != null) waterData['end_date'] = endDate;

//     // If activating, ensure global reminders are ON
//     if (isActive == true) {
//       waterData['reminders_enabled'] = true;
//       rootData['data'] = DateTime.now(); // Reset cycle
//     }

//     rootData['waterchallenge'] = waterData;
//     await _saveData(rootData);
//     await sync(hardSync: true);
//   }

//   Future<void> setSideChallengeNotification(
//     int slotIndex, {
//     bool? isActive,
//     String? title,
//     String? body,
//     int? hour,
//     int? minute,
//     DateTime? endDate,
//   }) async {
//     final Map<dynamic, dynamic> rootData = Map.from(notificationData);
//     final List<dynamic> sideList = List.from(rootData['sidechallenges']);

//     final int index = sideList.indexWhere((c) => c['slot_index'] == slotIndex);
//     if (index == -1) return;

//     final Map<dynamic, dynamic> challenge = Map.from(sideList[index]);

//     if (isActive != null) challenge['active'] = isActive;
//     if (title != null) challenge['title'] = title;
//     if (body != null) challenge['body'] = body;
//     if (hour != null) challenge['hour'] = hour;
//     if (minute != null) challenge['minute'] = minute;
//     if (endDate != null) challenge['end_date'] = endDate;

//     sideList[index] = challenge;
//     rootData['sidechallenges'] = sideList;
//     await _saveData(rootData);

//     if (isActive == false) {
//       await _cancelSideChallenge(slotIndex);
//     } else {
//       await sync(hardSync: true);
//     }
//   }

//   // ==========================================
//   // 5. INTERNAL HELPERS
//   // ==========================================

//   tz.TZDateTime _constructDateTime(
//     DateTime startDate,
//     int dayOffset,
//     int hour,
//     int minute,
//   ) {
//     return tz.TZDateTime(
//       tz.local,
//       startDate.year,
//       startDate.month,
//       startDate.day + dayOffset,
//       hour,
//       minute,
//     );
//   }

//   Future<void> _cancelAllWater() async {
//     for (int i = 0; i <= 7; i++) {
//       await _engine.cancelNotification(_waterMorningBaseId + i);
//       await _engine.cancelNotification(_waterAfternoonBaseId + i);
//       await _engine.cancelNotification(_waterEveningBaseId + i);
//     }
//     print("🚫 All Water Notifications Cancelled.");
//   }

//   Future<void> _cancelSideChallenge(int slotIndex) async {
//     final int baseId = slotIndex == 1 ? _extra1BaseId : _extra2BaseId;
//     for (int i = 0; i <= 7; i++) {
//       await _engine.cancelNotification(baseId + i);
//     }
//   }

//   // ==========================================
//   // 6. KILL SWITCHES (Today Only)
//   // ==========================================

//   /// Cancels only TODAY's water notifications (Morning, Afternoon, Evening).
//   /// Useful if user has already met their daily goal early.
//   Future<void> cancelTodayWater() async {
//     final data = notificationData;
//     if (data.isEmpty) return;

//     final DateTime setDate = data['data'];
//     final DateTime now = DateTime.now();

//     // Calculate which "Day Index" (0-7) corresponds to Today
//     final int dayIndex = now.difference(setDate).inDays;

//     // Only cancel if we are within the valid 7-day cycle
//     if (dayIndex >= 0 && dayIndex <= 7) {
//       print("🚫 Cancelling Water Reminders for Day $dayIndex (Today)...");

//       await _engine.cancelNotification(_waterMorningBaseId + dayIndex);
//       await _engine.cancelNotification(
//         _waterAfternoonBaseId + dayIndex,
//       ); // Don't forget Afternoon!
//       await _engine.cancelNotification(_waterEveningBaseId + dayIndex);
//     }
//   }

//   /// Cancels only TODAY's specific side challenge notification.
//   Future<void> cancelTodayExtra(int slotIndex) async {
//     final data = notificationData;
//     if (data.isEmpty) return;

//     final DateTime setDate = data['data'];
//     final DateTime now = DateTime.now();
//     final int dayIndex = now.difference(setDate).inDays;

//     if (dayIndex >= 0 && dayIndex <= 7) {
//       print("🚫 Cancelling Side Challenge $slotIndex for Day $dayIndex...");

//       final int baseId = slotIndex == 1 ? _extra1BaseId : _extra2BaseId;
//       await _engine.cancelNotification(baseId + dayIndex);
//     }
//   }
// }
