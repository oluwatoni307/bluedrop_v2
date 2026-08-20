import 'package:flutter/material.dart';

// --- MODELS & REPOSITORIES ---
import '../../data/challenge_model.dart';
import '../../data/challenges_repository.dart';
import '../../data/persona_repository.dart';

// --- WIDGETS ---
import '../widgets/active_challenge_row';
import '../widgets/market_place.dart';
import '../widgets/persona_card.dart';

// --- PAGES ---
import 'ChallengeDetailsPage.dart';

// --- SERVICES ---
import '../../../../services/database_service.dart';
import '../../../../services/api_service.dart';

class GoalsHubPage extends StatefulWidget {
  const GoalsHubPage({super.key});

  @override
  State<GoalsHubPage> createState() => _GoalsHubPageState();
}

class _GoalsHubPageState extends State<GoalsHubPage> {
  // Dependencies
  final ChallengesRepository _challengeRepo = ChallengesRepository();
  final PersonaRepository _personaRepo = PersonaRepository();
  final DatabaseService _db = DatabaseService();
  final ApiService _apiService = ApiService();

  // State Variables
  late Future<Map<String, String>> _personaFuture;
  late Future<List<Challenge>> _activeFuture;
  late Future<List<Challenge>> _availableFuture;
  int _currentWaterLog = 0;

  // UI Loading State for the specific shuffle action
  bool _isShuffling = false;

  @override
  void initState() {
    super.initState();
    _loadLocalData(); // 1. Instant UI render
    _checkAutoSync(); // 2. Background Weekly Check
  }

  // ===========================================================================
  // DATA LOADING & SYNC LOGIC
  // ===========================================================================

  /// Reads from Hive to populate the UI. Instant.
  void _loadLocalData() {
    setState(() {
      _personaFuture = _personaRepo.getPersona();
      _activeFuture = _challengeRepo.getActiveChallenges();
      _availableFuture = _challengeRepo.getAvailableChallenges();
      _loadWaterLog();
    });
  }

  /// Weekly Logic: Checks if 7 days have passed since the last Full Sync.
  Future<void> _checkAutoSync() async {
    try {
      final profile = await _db.getProfile();
      final lastSyncString = profile?['last_ai_sync'];

      final lastSync = lastSyncString != null
          ? DateTime.tryParse(lastSyncString)
          : null;

      // Logic: Sync if NEVER synced OR if > 7 days ago
      final shouldSync =
          lastSync == null || DateTime.now().difference(lastSync).inDays >= 7;

      if (shouldSync) {
        print("⏳ Auto-Sync Triggered (Weekly Check)...");

        // 1. Call Full Weekly Sync (Updates Persona + Challenges)
        await _apiService.performWeeklySync();

        // 2. Save new timestamp to Profile
        await _db.updateProfile({
          'last_ai_sync': DateTime.now().toIso8601String(),
        });

        // 3. Refresh UI if user is still here
        if (mounted) {
          _loadLocalData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("New weekly plan generated! 🧠"),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      print("⚠️ Auto-sync failed silently: $e");
    }
  }

  /// Manual Pull-to-Refresh: Forces a FULL Weekly Sync
  Future<void> _handleFullRefresh() async {
    try {
      await _apiService.performWeeklySync();
      await _db.updateProfile({
        'last_ai_sync': DateTime.now().toIso8601String(),
      });
      _loadLocalData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Synced with AI Coach!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sync failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shuffle Button: Updates Challenges ONLY (Keeps Persona)
  Future<void> _handleShuffle() async {
    setState(() => _isShuffling = true);

    try {
      await _apiService.shuffleChallenges();
      _loadLocalData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New challenges loaded! 🎲")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Shuffle failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isShuffling = false);
    }
  }

  Future<void> _loadWaterLog() async {
    final logs = await _db.getAllFromCollection('waterLogs');
    final now = DateTime.now();

    final todayLogs = logs.where((l) {
      if (l['createdAt'] == null) return false;
      final date = DateTime.parse(l['createdAt']);
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    });

    int total = 0;
    for (var log in todayLogs) {
      total += (log['amount'] as num).toInt();
    }

    if (mounted) setState(() => _currentWaterLog = total);
  }

  // ===========================================================================
  // INTERACTION LOGIC
  // ===========================================================================

  void _onToggleHabit(Challenge challenge) async {
    await _challengeRepo.toggleHabitForToday(challenge);
    _loadLocalData();
  }

  void _navigateToDetails(Challenge challenge) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeDetailsPage(
          challenge: challenge,
          currentWaterLog: _currentWaterLog,
        ),
      ),
    );
    if (result == true) {
      _loadLocalData();
    }
  }

  // ===========================================================================
  // UI BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Goals Hub",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _handleFullRefresh, // Pull down for FULL Sync
        color: Colors.blue,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PERSONA SECTION
              FutureBuilder<Map<String, String>>(
                future: _personaFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 100);
                  final data = snapshot.data!;
                  return PersonaCard(
                    name: data['name'] ?? 'User',
                    tag: data['tag'] ?? 'Novice',
                    bio: data['bio'] ?? 'Ready to start!',
                  );
                },
              ),

              const SizedBox(height: 20),

              // 2. MARKETPLACE HEADER (With Shuffle Button)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Explore Challenges",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Shuffle / Reroll Button
                    TextButton.icon(
                      onPressed: _isShuffling ? null : _handleShuffle,
                      icon: _isShuffling
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.shuffle,
                              size: 18,
                              color: Colors.blue,
                            ),
                      label: Text(
                        _isShuffling ? "Loading..." : "Shuffle",
                        style: const TextStyle(color: Colors.blue),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. MARKETPLACE CAROUSEL
              SizedBox(
                height: 160,
                child: FutureBuilder<List<Challenge>>(
                  future: _availableFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !_isShuffling) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return MarketplaceCard(
                          challenge: snapshot.data![index],
                          onTap: () =>
                              _navigateToDetails(snapshot.data![index]),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // 4. ACTIVE DASHBOARD SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text(
                  "Active Goals",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Challenge>>(
                future: _activeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.directions_run,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "No active goals.\nChoose one from above!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: snapshot.data!.map((challenge) {
                      final isHabit = challenge.type == ChallengeType.habitSide;
                      return GestureDetector(
                        onTap: () => _navigateToDetails(challenge),
                        child: ActiveChallengeRow(
                          challenge: challenge,
                          currentWaterLog: _currentWaterLog,
                          onToggleHabit: isHabit
                              ? () => _onToggleHabit(challenge)
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "All caught up!",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Pull down to force sync\nor click Shuffle.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
