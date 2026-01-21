import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../analytics/analytics_model.dart';
import '../analytics/analytics_provider.dart';
import 'home_model.dart';
import 'home_provider.dart';
import 'components/motivational_header.dart';
import 'components/today_progress_card.dart';
import 'components/info_cards_row.dart';
import '../analytics/components/insights_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load everything when the screen first mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  /// The Master Refresh Function
  /// Loads Today's Progress AND Weekly Analytics simultaneously.
  Future<void> _refreshAllData() async {
    // 1. Load Today's Data
    final homeFuture = ref.read(homeProvider.notifier).loadTodayData();

    // 2. Load Weekly Analytics (so the card is always fresh)
    ref.read(analyticsProvider.notifier).setPeriod(TimePeriod.week);
    final analyticsFuture = ref.read(analyticsProvider.notifier).refresh();

    await Future.wait([homeFuture, analyticsFuture]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              // LOADING STATE
              if (state.isLoading && state.todayProgress == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              // EMPTY STATE
              else if (state.todayProgress == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ready to hydrate?',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              // CONTENT
              else ...[
                MotivationalHeader(
                  userName: state.userName,
                  percentage: state.todayProgress?.percentage ?? 0,
                ),
                const SizedBox(height: 10),

                TodayProgressCard(
                  totalAmount: state.todayProgress?.totalAmount ?? 0,
                  goalAmount: state.todayProgress?.goalAmount ?? 2500,
                  percentage: state.todayProgress?.percentage ?? 0,

                  // 🔥 THE LISTENER LOGIC
                  onLogWater: () async {
                    // 1. Go to Log Screen and PAUSE execution here
                    await context.pushNamed('log');

                    // 2. Resume when user comes back & Reload from disk
                    if (mounted) {
                      await _refreshAllData();
                    }
                  },
                ),
                const SizedBox(height: 15),

                InfoCardsRow(
                  glassLevel: (state.todayProgress?.percentage ?? 0) / 100,
                  lastLogTime: _formatLastLogTime(state.lastLog),
                  lastLogAmount: state.lastLog?.amount ?? 0,

                  // 🔥 UPDATED PARAMETER
                  activeChallengesCount: state.activeSideChallenges.length,
                ),
                const SizedBox(height: 5),

                // This card listens to the same analytics provider
                const InsightsCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastLogTime(LastLog? lastLog) {
    if (lastLog == null) return 'N/A';
    final time = lastLog.timestamp;
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
