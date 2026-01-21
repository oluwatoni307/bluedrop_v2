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
}
