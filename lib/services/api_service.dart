import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import '../features/hub/data/challenge_model.dart';

class ApiService {
  // REPLACE WITH YOUR PYTHON URL
  static const String _baseUrl = 'https://your-python-backend.com/api';

  final DatabaseService _db = DatabaseService();

  /// 1. MAIN METHOD: Gather Data -> Send to Python -> Save Response
  Future<void> syncWithAI() async {
    try {
      print("🚀 Gathering User Data...");

      // A. Get Auth Token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      final token = await user.getIdToken();

      // B. Collect Local Data (The Context)
      final userDataPayload = await _collectUserData();

      print("📤 Sending Payload to Python: ${jsonEncode(userDataPayload)}");

      // C. Send to Backend
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-challenges'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userDataPayload), // <--- DUMPING THE DATA HERE
      );

      // D. Handle Response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        await _processBackendResponse(responseData);
        print("✅ AI Sync Complete");
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Sync Failed: $e");
    }
  }

  /// 2. HELPER: Gather last 7 days of data
  Future<Map<String, dynamic>> _collectUserData() async {
    // --- Get Profile ---
    final profile = await _db.getProfile() ?? {};

    // --- Get Water Logs (Last 7 Days) ---
    final allLogs = await _db.getAllFromCollection('water_logs');
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final recentLogs = allLogs
        .where((log) {
          final date = DateTime.parse(log['createdAt']); // Assuming ISO string
          return date.isAfter(sevenDaysAgo);
        })
        .map((log) => {'amount': log['amount'], 'timestamp': log['createdAt']})
        .toList();

    // --- Get Active Challenges (Context) ---
    // We want the AI to know what challenges are already active
    final allChallenges = await _db.getAllFromCollection('challenges');
    final activeChallenges = allChallenges
        .map((c) => Challenge.fromMap(c))
        .where((c) => c.status == ChallengeStatus.active)
        .map((c) => c.id) // Send only IDs or Titles to save bandwidth
        .toList();

    return {
      'user_id': FirebaseAuth.instance.currentUser?.uid,
      'profile': {
        'name': profile['name'],
        'daily_goal': profile['daily_goal'],
        // Add weight/height here if you have it
      },
      'recent_logs': recentLogs,
      'active_challenges': activeChallenges,
      'client_time': now.toIso8601String(),
    };
  }

  /// 3. HELPER: Save the AI's response to Hive
  Future<void> _processBackendResponse(Map<String, dynamic> data) async {
    // [Same as before: Update Persona and Challenges]
    if (data.containsKey('persona')) {
      final persona = data['persona'];
      await _db.updateProfile({'tag': persona['tag'], 'bio': persona['bio']});
    }

    if (data.containsKey('recommendations')) {
      final List challenges = data['recommendations'];
      final boxName = 'challenges';
      for (var item in challenges) {
        final challenge = Challenge.fromMap(Map<String, dynamic>.from(item));
        await _db.updateInCollection(boxName, challenge.id, challenge.toMap());
      }
    }
  }
}
