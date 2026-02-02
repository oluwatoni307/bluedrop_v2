import '../../../../services/database_service.dart'; // Import your main service
import 'challenge_model.dart';

class ChallengesRepository {
  final DatabaseService _db = DatabaseService();
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
    // 1. Conflict Check (Max 1 Water Challenge)
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
    }

    // 2. Set Active
    final updated = challenge.copyWith(
      status: ChallengeStatus.active,
      startDate: DateTime.now(),
    );
    await _db.updateInCollection(_boxName, challenge.id, updated.toMap());
  }

  Future<void> leaveChallenge(Challenge challenge) async {
    // 1. Revert Goal
    if (challenge.type == ChallengeType.waterMain) {
      final profile = await _db.getProfile();
      if (profile != null && profile['base_goal_backup'] != null) {
        await _db.updateProfile({
          'dailyGoal': profile['base_goal_backup'],
          'base_goal_backup': null,
        });
      }
    }

    // 2. Reset Status
    final reset = challenge.copyWith(
      status: ChallengeStatus.available,
      startDate: null,
      completedDates: [],
    );
    await _db.updateInCollection(_boxName, challenge.id, reset.toMap());
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
      newDates.removeWhere(
        (d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day,
      );
    } else {
      newDates.add(today);
    }

    final updated = challenge.copyWith(completedDates: newDates);
    await _db.updateInCollection(_boxName, challenge.id, updated.toMap());
  }

  // challenges_repository.dart

  // ... existing code ...

  /// Replaces only the 'Available' challenges with new AI recommendations.
  /// Preserves 'Active' and 'Completed' challenges.
  Future<void> replaceAvailableChallenges(
    List<Challenge> newRecommendations,
  ) async {
    // 1. Get ALL current data
    final allData = await _db.getAllFromCollection(_boxName);
    final allChallenges = allData.map((e) => Challenge.fromMap(e)).toList();

    // 2. Filter out the ones we want to KEEP (Active & Completed)
    final _ = allChallenges
        .where(
          (c) =>
              c.status == ChallengeStatus.active ||
              c.status == ChallengeStatus.completed,
        )
        .toList();

    // 3. Prepare the new list (Keepers + New Recommendations)
    // Note: Ensure new recommendations are set to 'available' status
    final validRecommendations = newRecommendations
        .map((c) => c.copyWith(status: ChallengeStatus.available))
        .toList();

    // 4. clear collection and rewrite?
    // Hive doesn't have a "delete where". It's safer to clear and rewrite
    // OR delete specific IDs.
    // Strategy: Delete ONLY the old "available" ones first.

    final idsToDelete = allChallenges
        .where((c) => c.status == ChallengeStatus.available)
        .map((c) => c.id)
        .toList();

    for (var id in idsToDelete) {
      await _db.deleteFromCollection(_boxName, id);
    }

    // 5. Add the new ones
    for (var challenge in validRecommendations) {
      // Use updateInCollection or addToCollection depending on if you have IDs
      // Assuming AI generates IDs, we use update (upsert)
      await _db.saveDocument(_boxName, challenge.id, challenge.toMap());
    }
  }
}
