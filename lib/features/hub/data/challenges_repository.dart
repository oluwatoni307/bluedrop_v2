import '../../../../services/database_service.dart';
import 'challenge_model.dart';

class ChallengesRepository {
  final DatabaseService _db = DatabaseService();
  // final NotificationService _notifications =
  //     NotificationService(); // Inject Service
  final String _boxName = 'challenges';

  // --- READ ---
  Future<List<Challenge>> getActiveChallenges() async {
    final allData = await _db.getAllFromCollection(_boxName);
    return allData
        .map((e) => Challenge.fromMap(e))
        .where((c) => c.status == ChallengeStatus.active)
        .toList();
  }

  Future<List<Challenge>> getAvailableChallenges() async {
    final allData = await _db.getAllFromCollection(_boxName);
    return allData
        .map((e) => Challenge.fromMap(e))
        .where((c) => c.status == ChallengeStatus.available)
        .toList();
  }

  // --- WRITE ---

  Future<void> joinChallenge(Challenge challenge) async {
    // 1. WATER CHALLENGE LOGIC
    if (challenge.type == ChallengeType.waterMain) {
      final active = await getActiveChallenges();
      if (active.any((c) => c.type == ChallengeType.waterMain)) {
        throw Exception("Active Water Challenge exists. Cancel it first.");
      }

      // Backup & Override Goal
      final profile = await _db.getProfile();
      if (profile != null) {
        if (profile['base_goal_backup'] == null) {
          await _db.updateProfile({
            'base_goal_backup': profile['dailyGoal'] ?? 2000,
          });
        }
        await _db.updateProfile({'dailyGoal': challenge.targetVolume});
      }

      // START NOTIFICATIONS (WATER)
      // Defaults to active=true, start=Now, end=30 days (or challenge duration)
      // await _notifications.setWaterChallenge(
      //   isActive: true,
      //   title: challenge.title,
      //   body: challenge.description,
      //   endDate: DateTime.now().add(const Duration(days: 30)),
      // );
    }
    // 2. SIDE CHALLENGE LOGIC (Habit/Skill)
    else {
      // We need to assign a "Notification Slot" (1 or 2)
      final activeChallenges = await getActiveChallenges();

      // Filter only side challenges to see which slots are taken
      final activeSide = activeChallenges
          .where((c) => c.type != ChallengeType.waterMain)
          .toList();

      if (activeSide.length >= 2) {
        throw Exception("You can only have 2 active side challenges at once.");
      }

      // Simple Slot Assigner:
      // If no side challenges, take Slot 1.
      // If 1 exists, check its slot. If it's Slot 1, take Slot 2.
      int targetSlot = 1;
      if (activeSide.isNotEmpty) {
        // Assuming we store 'notificationSlot' in the DB map
        // We might need to fetch the raw map to see the slot if it's not on the model
        final rawData = await _db.getFromCollection(
          _boxName,
          activeSide.first.id,
        );
        final int usedSlot = rawData?['notificationSlot'] ?? 1;
        targetSlot = (usedSlot == 1) ? 2 : 1;
      }

      // // START NOTIFICATIONS (SIDE)
      // await _notifications.setSideChallengeNotification(
      //   targetSlot,
      //   isActive: true,
      //   title: challenge.title,
      //   body: challenge.description,
      //   hour: 10, // Default to 10 AM (You could add a time picker later)
      //   minute: 0,
      //   endDate: DateTime.now().add(const Duration(days: 14)),
      // );

      // SAVE SLOT TO DB
      // We explicitly save 'notificationSlot' so we know which one to cancel later
      final updatedMap = challenge.toMap();
      updatedMap['notificationSlot'] = targetSlot;

      final updated = challenge.copyWith(
        status: ChallengeStatus.active,
        startDate: DateTime.now(),
      );

      // Merge our slot into the update
      final finalMap = updated.toMap();
      finalMap['notificationSlot'] = targetSlot;

      await _db.updateInCollection(_boxName, challenge.id, finalMap);
      return; // Return early since we handled the DB update manually above
    }

    // 3. DATABASE UPDATE (For Water)
    final updated = challenge.copyWith(
      status: ChallengeStatus.active,
      startDate: DateTime.now(),
    );
    await _db.updateInCollection(_boxName, challenge.id, updated.toMap());
  }

  Future<void> leaveChallenge(Challenge challenge) async {
    // 1. WATER LOGIC
    if (challenge.type == ChallengeType.waterMain) {
      // Revert Goal
      final profile = await _db.getProfile();
      if (profile != null && profile['base_goal_backup'] != null) {
        await _db.updateProfile({
          'dailyGoal': profile['base_goal_backup'],
          'base_goal_backup': null,
        });
      }

      // STOP NOTIFICATIONS
      // await _notifications.setWaterChallenge(isActive: false);
    }
    // 2. SIDE CHALLENGE LOGIC
    else {
      // // We need to know which slot this challenge was using
      // final rawData = await _db.getFromCollection(_boxName, challenge.id);
      // final int? slotUsed = rawData?['notificationSlot'];

      // if (slotUsed != null) {
      //   // STOP NOTIFICATIONS for that specific slot
      //   await _notifications.setSideChallengeNotification(
      //     slotUsed,
      //     isActive: false,
      //   );
      // }
    }

    // 3. DATABASE RESET
    final reset = challenge.copyWith(
      status: ChallengeStatus.available,
      startDate: null,
      completedDates: [],
    );
    // Note: We keep 'notificationSlot' in DB or clear it.
    // It doesn't hurt to leave it, but clearing is cleaner.
    final resetMap = reset.toMap();
    resetMap['notificationSlot'] = null;

    await _db.updateInCollection(_boxName, challenge.id, resetMap);
  }

  Future<void> toggleHabitForToday(Challenge challenge) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<DateTime> newDates = List.from(challenge.completedDates);

    // Check if exists
    final exists = newDates.any(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );

    if (exists) {
      // UN-CHECKING (Removing completion)
      newDates.removeWhere(
        (d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day,
      );
      // NOTE: We cannot easily "Re-schedule" a cancelled alarm for today
      // without running a full sync or complex logic.
      // Usually, un-checking is rare enough that we accept the alarm is gone for today.
    } else {
      // CHECKING (Marking as done)
      newDates.add(today);

      // // KILL SWITCH: Cancel the alarm for today since they did it!
      // if (challenge.type == ChallengeType.waterMain) {
      //   await _notifications.cancelTodayWater();
      // } else {
      //   // Retrieve slot from DB
      //   final rawData = await _db.getFromCollection(_boxName, challenge.id);
      //   final int? slot = rawData?['notificationSlot'];
      //   if (slot != null) {
      //     await _notifications.cancelTodayExtra(slot);
      //   }
      // }
    }

    final updated = challenge.copyWith(completedDates: newDates);
    await _db.updateInCollection(_boxName, challenge.id, updated.toMap());
  }

  // --- REPLACEMENT LOGIC (No changes needed here) ---
  Future<void> replaceAvailableChallenges(
    List<Challenge> newRecommendations,
  ) async {
    final allData = await _db.getAllFromCollection(_boxName);
    final allChallenges = allData.map((e) => Challenge.fromMap(e)).toList();

    // Keep Active & Completed
    final keepIds = allChallenges
        .where(
          (c) =>
              c.status == ChallengeStatus.active ||
              c.status == ChallengeStatus.completed,
        )
        .map((c) => c.id)
        .toSet();

    // Identify Available to delete
    final idsToDelete = allChallenges
        .where((c) => c.status == ChallengeStatus.available)
        .map((c) => c.id)
        .toList();

    for (var id in idsToDelete) {
      await _db.deleteFromCollection(_boxName, id);
    }

    // Add new recommendations
    for (var challenge in newRecommendations) {
      // Only add if it's not already in the "Keep" list (duplicate protection)
      if (!keepIds.contains(challenge.id)) {
        final ready = challenge.copyWith(status: ChallengeStatus.available);
        await _db.saveDocument(_boxName, ready.id, ready.toMap());
      }
    }
  }
}
