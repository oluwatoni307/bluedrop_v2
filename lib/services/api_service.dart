import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'database_service.dart';
import '../features/hub/data/challenge_model.dart';
import '../features/hub/data/challenges_repository.dart';

class WaterLevelEstimate {
  final double fillPercentage;
  final int capacity;

  const WaterLevelEstimate({
    required this.fillPercentage,
    required this.capacity,
  });
}

class ApiService {
  // ---------------------------------------------------------------------------
  // CONFIGURATION
  // ---------------------------------------------------------------------------

  // Production URL for Render deployment
  static const String _baseUrl = 'https://bluedrop-backend.onrender.com';

  final DatabaseService _db = DatabaseService();
  final ChallengesRepository _challengesRepo = ChallengesRepository();

  // ---------------------------------------------------------------------------
  // 1. PUBLIC METHODS
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // 0. HEALTH CHECK (PING)
  // ---------------------------------------------------------------------------

  /// Checks if the backend is awake. Essential for Render's "spin-up" delay.
  Future<bool> checkServerHealth() async {
    final url = Uri.parse('$_baseUrl/ping');
    print("📡 [ApiService] Pinging server at $url...");

    try {
      // Shorter timeout for a simple ping
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("🟢 [ApiService] Server is Online: ${decoded['message']}");
        return true;
      }
    } catch (e) {
      print("🟠 [ApiService] Server is sleeping or unreachable: $e");
    }
    return false;
  }

  String _getNigerianSeason() {
    final month = DateTime.now().month;

    if (month >= 4 && month <= 10) {
      return "Rainy Season";
    } else if (month == 12 || month == 1) {
      return "Harmattan Season";
    } else {
      return "Dry Season";
    }
  }

  Future<void> performWeeklySync() async {
    print("🚀 [ApiService] Starting Weekly Sync...");

    final season = _getNigerianSeason();
    final payload = await _collectUserData();
    payload['current_season'] = season;
    payload['sync_region'] = "NG";

    final jsonString = jsonEncode(payload);

    await Future.wait([
      _updateProfile(jsonString),
      _updateChallenges(jsonString),
    ]);

    print("✨ [ApiService] Weekly Sync Complete during $season!");
  }

  Future<void> shuffleChallenges() async {
    print("🎲 [ApiService] Shuffling Challenges...");

    final payload = await _collectUserData();
    final jsonString = jsonEncode(payload);

    await _updateChallenges(jsonString);

    print("✅ [ApiService] Challenges Shuffled!");
  }

  // ---------------------------------------------------------------------------
  // 2. NETWORK RETRY MECHANISM
  // ---------------------------------------------------------------------------

  Future<http.Response> _postWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int maxRetries = 2,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        attempt++;
        print("📡 [ApiService] Attempt $attempt to $url...");

        return await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 45));
      } on TimeoutException {
        print("⚠️ [ApiService] Timeout on attempt $attempt.");
        if (attempt >= maxRetries) {
          throw Exception('Server initialization timeout exceeded.');
        }
      } catch (e) {
        print("❌ [ApiService] Network error: $e");
        rethrow;
      }
    }
    throw Exception('Request failed completely.');
  }

  // ---------------------------------------------------------------------------
  // 3. PRIVATE ENDPOINT CALLERS
  // ---------------------------------------------------------------------------

  Future<void> _updateProfile(String jsonData) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      final response = await _postWithRetry(
        Uri.parse('$_baseUrl/profile'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        body: {'data': jsonData},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
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

      final response = await _postWithRetry(
        Uri.parse('$_baseUrl/challenge'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        body: {'data': jsonData},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded.containsKey('challenges')) {
          var content = decoded['challenges'];

          if (content is Map<String, dynamic> &&
              content.containsKey('challenges')) {
            content = content['challenges'];
          }

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
  // 4. DATA COLLECTION
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _collectUserData() async {
    final profile = await _db.getProfile() ?? {};
    final allChallengeDocs = await _db.getAllFromCollection('challenges');

    final allChallenges = allChallengeDocs.map((c) => Challenge.fromMap(c));

    return {
      'client_time': DateTime.now().toIso8601String(),
      'profile': {
        'name': profile['name'] ?? 'User',
        'bio': profile['bio'] ?? '',
        'tag': profile['tag'] ?? '',
      },
      'active_challenges': allChallenges
          .where((c) => c.status == ChallengeStatus.active)
          .map((c) => c.toMap())
          .toList(),
      'completed_challenges': allChallenges
          .where((c) => c.status == ChallengeStatus.completed)
          .map((c) => c.toMap())
          .toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // 5. IMAGE RECOGNITION
  // ---------------------------------------------------------------------------

  /// Estimates how full a container is from an image.
  ///
  /// This endpoint is separate from [recognizeContainer], which identifies
  /// cabinet containers and returns metadata such as name and volume.
  Future<WaterLevelEstimate?> estimateWaterLevel(
    Uint8List imageBytes,
    String fileName,
  ) async {
    const String endpoint = '$_baseUrl/water-level';
    final request = http.MultipartRequest('POST', Uri.parse(endpoint));
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final response = await request.send().timeout(const Duration(seconds: 45));
    final responseBody = await http.Response.fromStream(response);

    if (response.statusCode != 200) {
      print(
        "❌ [ApiService] Water-level error: ${response.statusCode} - ${responseBody.body}",
      );
      return null;
    }

    final decoded = jsonDecode(responseBody.body);
    final payload = decoded is Map<String, dynamic>
        ? decoded['analysis'] ?? decoded
        : decoded;
    if (payload is! Map<String, dynamic>) return null;

    final value = payload['fill_percentage'] ?? payload['fillPercent'];
    final capacityValue = payload['capacity'];
    final percentage = value is num ? value.toDouble() : null;
    final capacity = capacityValue is num ? capacityValue.toInt() : null;

    if (percentage == null || capacity == null || capacity <= 0) return null;
    return WaterLevelEstimate(
      fillPercentage: (percentage / 100).clamp(0.0, 1.0),
      capacity: capacity,
    );
  }

  Future<Map<String, dynamic>?> recognizeContainer(
    Uint8List imageBytes,
    String fileName,
  ) async {
    const String endpoint = '$_baseUrl/recognize';
    print(
      "📷 [ApiService] Uploading image (${imageBytes.length} bytes) to $endpoint...",
    );

    int attempt = 0;
    const int maxRetries = 2;

    while (attempt < maxRetries) {
      try {
        attempt++;
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();

        // Instantiate a new request per attempt because streams cannot be reused.
        final request = http.MultipartRequest('POST', Uri.parse(endpoint));

        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: fileName,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 45),
        );
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          var analysisData = decoded['analysis'];

          if (analysisData is List && analysisData.isNotEmpty) {
            final firstPart = analysisData.first;
            if (firstPart is Map<String, dynamic>) {
              analysisData = firstPart['text'] ?? firstPart;
            }
          }

          if (analysisData is String) {
            try {
              final cleanJson = analysisData
                  .replaceAll(RegExp(r'```json|```'), '')
                  .trim();
              return jsonDecode(cleanJson) as Map<String, dynamic>;
            } catch (e) {
              return null;
            }
          }

          if (analysisData is Map<String, dynamic>) {
            return analysisData;
          }
        } else {
          print(
            "❌ [ApiService] Upload Error: ${response.statusCode} - ${response.body}",
          );
          return null; // Do not retry client errors like 400 or 500
        }
      } on TimeoutException {
        print("⚠️ [ApiService] Timeout on image upload attempt $attempt.");
        if (attempt >= maxRetries) {
          return null;
        }
      } catch (e) {
        print("❌ [ApiService] Connection Failed: $e");
        return null;
      }
    }
    return null;
  }
}
