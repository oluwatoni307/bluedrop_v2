import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../services/database_service.dart';

import '../hub/data/challenge_model.dart';
import '../hub/data/challenges_repository.dart';
import 'home_model.dart';

part 'home_provider.g.dart';

class HomeState {
  final bool isLoading;
  final String? error;
  final TodayProgress? todayProgress;
  final LastLog? lastLog;
  final int dailyGoal;
  final String userName;

  // 🔥 NEW: Holds the list of active side quests (habits)
  final List<Challenge> activeSideChallenges;

  const HomeState({
    this.todayProgress,
    this.lastLog,
    this.dailyGoal = 2500,
    this.userName = 'User',
    this.isLoading = false,
    this.error,
    this.activeSideChallenges = const [], // Default to empty list
  });

  HomeState copyWith({
    TodayProgress? todayProgress,
    LastLog? lastLog,
    int? dailyGoal,
    String? userName,
    bool? isLoading,
    String? error,
    List<Challenge>? activeSideChallenges, // Add to copyWith
  }) {
    return HomeState(
      todayProgress: todayProgress ?? this.todayProgress,
      lastLog: lastLog ?? this.lastLog,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      userName: userName ?? this.userName,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      activeSideChallenges: activeSideChallenges ?? this.activeSideChallenges,
    );
  }
}

@riverpod
class Home extends _$Home {
  @override
  HomeState build() {
    return const HomeState();
  }

  Future<void> loadTodayData() async {
    // Only set loading to true if we don't have data yet to prevent UI flicker
    if (state.todayProgress == null) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final db = DatabaseService();
      final challengesRepo = ChallengesRepository();

      // 1. Get today's date range
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // 2. Query today's logs
      final logs = await db.queryCollection(
        'waterLogs',
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // 3. Get user profile
      final profile = await db.getProfile();
      final goal = profile?['dailyGoal'] as int? ?? 2500;
      final name = profile?['name'] as String? ?? 'User'; // NEW
      // 4. Get Active Challenges
      final allActive = await challengesRepo.getActiveChallenges();
      // Filter: Only keep "Side Habits" (exclude the main water challenge)
      final sideChallenges = allActive
          .where((c) => c.type != ChallengeType.waterMain)
          .toList();

      // 5. Calculate today's progress
      final totalAmount = logs.fold<int>(
        0,
        (sum, log) => sum + (log['amount'] as int? ?? 0),
      );
      final percentage = goal > 0 ? (totalAmount / goal) * 100 : 0.0;

      final todayProgress = TodayProgress(
        totalAmount: totalAmount,
        goalAmount: goal,
        percentage: percentage,
        logsCount: logs.length,
        date: startOfDay,
      );

      // 6. Get last log (Safely sorted)
      LastLog? lastLog;
      if (logs.isNotEmpty) {
        logs.sort((a, b) {
          final tA = DateTime.parse(a['timestamp'] as String);
          final tB = DateTime.parse(b['timestamp'] as String);
          return tB.compareTo(tA);
        });

        final latestLogData = logs.first;

        lastLog = LastLog(
          amount: latestLogData['amount'] as int? ?? 0,
          timestamp: DateTime.parse(latestLogData['timestamp'] as String),
          drinkType: latestLogData['drinkType'] as String? ?? 'water',
        );
      }

      // 7. Update state
      state = state.copyWith(
        todayProgress: todayProgress,
        lastLog: lastLog,
        dailyGoal: goal,
        userName: name,
        activeSideChallenges: sideChallenges, // 🔥 Populate the list
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load data: $e',
      );
    }
  }

  /// Action to toggle a side habit (called from UI)
  Future<void> toggleSideChallenge(Challenge challenge) async {
    try {
      final repo = ChallengesRepository();
      await repo.toggleHabitForToday(challenge);
      // Reload to update the UI (checkmark state)
      await loadTodayData();
    } catch (e) {
      print("Error toggling habit: $e");
    }
  }

  Future<void> refreshData() async {
    await loadTodayData();
  }
}
