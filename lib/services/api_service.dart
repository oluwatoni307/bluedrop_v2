import 'dart:convert';
import 'dart:typed_data'; // Required for Uint8List
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Required for MediaType
import 'package:firebase_auth/firebase_auth.dart';

import 'database_service.dart';
import '../features/hub/data/challenge_model.dart';
import '../features/hub/data/challenges_repository.dart';

class ApiService {
  // ---------------------------------------------------------------------------
  // CONFIGURATION
  // ---------------------------------------------------------------------------

  // TODO: Replace with your actual Python Backend URL
  // Web: 'http://localhost:8000'
  // Android Emulator: 'http://10.0.2.2:8000'
  // Physical Device: 'http://YOUR_PC_IP:8000'
  static const String _baseUrl = 'http://localhost:8000';

  final DatabaseService _db = DatabaseService();
  final ChallengesRepository _challengesRepo = ChallengesRepository();

  // ---------------------------------------------------------------------------
  // 1. PUBLIC METHODS (The "Controls")
  // ---------------------------------------------------------------------------

  /// WEEKLY SYNC: Updates Persona AND Challenges
  Future<void> performWeeklySync() async {
    print("🚀 [ApiService] Starting Weekly Sync (Profile + Challenges)...");

    final payload = await _collectUserData();
    final jsonString = jsonEncode(payload);

    // Run both requests in parallel to save time
    await Future.wait([
      _updateProfile(jsonString),
      _updateChallenges(jsonString),
    ]);

    print("✨ [ApiService] Weekly Sync Complete!");
  }

  /// SHUFFLE: Updates Challenges ONLY
  Future<void> shuffleChallenges() async {
    print("🎲 [ApiService] Shuffling Challenges...");

    final payload = await _collectUserData();
    final jsonString = jsonEncode(payload);

    // Only hit the challenge endpoint
    await _updateChallenges(jsonString);

    print("✅ [ApiService] Challenges Shuffled!");
  }

  // ---------------------------------------------------------------------------
  // 2. PRIVATE ENDPOINT CALLERS
  // ---------------------------------------------------------------------------

  Future<void> _updateProfile(String jsonData) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      // Note: We send 'body' as a Map to satisfy FastAPI 'Form(...)'
      final response = await http.post(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          // Library automatically sets Content-Type to application/x-www-form-urlencoded
        },
        body: {'data': jsonData},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Expecting: {"profile": { "tag": "...", "bio": "..." }}
        if (decoded.containsKey('profile')) {
          final persona = decoded['profile'];
          await _db.updateProfile({
            'tag': persona['tag'],
            'bio': persona['bio'],
          });
          print("👤 [ApiService] Persona Updated.");
        }
      } else {
        print("❌ [ApiService] Profile Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ [ApiService] Profile Request Failed: $e");
    }
  }

  Future<void> _updateChallenges(String jsonData) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/challenge'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        body: {'data': jsonData},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // 1. Check for the Outer Key
        if (decoded.containsKey('challenges')) {
          var content = decoded['challenges'];

          // -----------------------------------------------------------
          // FIX: Handle the "Double Wrap" Case
          // -----------------------------------------------------------
          // If 'content' is actually a Map (the inner dict), unwrap it again.
          if (content is Map<String, dynamic> &&
              content.containsKey('challenges')) {
            print(
              "⚠️ [ApiService] Detected double-wrapped JSON. Unwrapping...",
            );
            content = content['challenges'];
          }

          // 2. Now safely cast to List
          if (content is List) {
            final List rawList = content;

            final List<Challenge> newChallenges = rawList.map((item) {
              final map = Map<String, dynamic>.from(item);
              map['status'] ??= ChallengeStatus.available.index;
              return Challenge.fromMap(map);
            }).toList();

            if (newChallenges.isNotEmpty) {
              await _challengesRepo.replaceAvailableChallenges(newChallenges);
              print(
                "🔄 [ApiService] Challenges Replaced: ${newChallenges.length} items.",
              );
            }
          } else {
            print(
              "❌ [ApiService] Expected List but got ${content.runtimeType}",
            );
          }
        }
      } else {
        print("❌ [ApiService] Challenge Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ [ApiService] Challenge Request Failed: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 3. DATA COLLECTION (The "Packer")
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _collectUserData() async {
    final profile = await _db.getProfile() ?? {};
    final _ = await _db.getAllFromCollection('waterLogs');
    final allChallengeDocs = await _db.getAllFromCollection('challenges');

    // Convert Docs to Models
    final allChallenges = allChallengeDocs.map((c) => Challenge.fromMap(c));

    return {
      'client_time': DateTime.now().toIso8601String(),
      'profile': {
        'name': profile['name'] ?? 'User',
        'bio': profile['bio'] ?? '',
        'tag': profile['tag'] ?? '',
      },
      // Simplified: Just sending the lists.
      // Your Python 'text_agent' will need to parse these lists.
      'active_challenges': allChallenges
          .where((c) => c.status == ChallengeStatus.active)
          .map((c) => c.toMap())
          .toList(),
      'completed_challenges': allChallenges
          .where((c) => c.status == ChallengeStatus.completed)
          .map((c) => c.toMap())
          .toList(),
      // Add water logs filtering logic here if needed
    };
  }

  /// ---------------------------------------------------------------------------
  /// 4. IMAGE RECOGNITION (Updated for Web Support)
  /// ---------------------------------------------------------------------------

  /// Accepts [imageBytes] (Uint8List) instead of File to support Web & Mobile.
  /// [fileName] helps the backend identify the file format (e.g. "photo.jpg").
  Future<Map<String, dynamic>?> recognizeContainer(
    Uint8List imageBytes,
    String fileName,
  ) async {
    const String endpoint = '$_baseUrl/recognize';
    print(
      "📷 [ApiService] Uploading image (${imageBytes.length} bytes) to $endpoint...",
    );

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      // 1. Prepare Multipart Request
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));

      // 2. Add Headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 3. Add the Image File (Using fromBytes for Web compatibility)
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // Key expected by backend
          imageBytes,
          filename: fileName,
          contentType: MediaType(
            'image',
            'jpeg',
          ), // Adjust if supporting PNG/etc
        ),
      );

      // 4. Send & Await
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 5. Handle Response
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("✅ [ApiService] AI Analysis Received: $decoded");

        // The endpoint returns: {"analysis": ...data... }
        var analysisData = decoded['analysis'];

        // Safety Check: If backend returns a JSON string inside the JSON
        if (analysisData is String) {
          try {
            // Strip potential markdown (```json ... ```) just in case
            final cleanJson = analysisData
                .replaceAll(RegExp(r'```json|```'), '')
                .trim();
            return jsonDecode(cleanJson) as Map<String, dynamic>;
          } catch (e) {
            print("⚠️ Could not parse analysis string: $e");
            return null;
          }
        }

        // Standard Case: It's already a Map
        if (analysisData is Map<String, dynamic>) {
          return analysisData;
        }
      } else {
        print(
          "❌ [ApiService] Upload Error: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("❌ [ApiService] Connection Failed: $e");
    }

    return null; // Return null on failure so UI can show error/manual entry
  }
}
