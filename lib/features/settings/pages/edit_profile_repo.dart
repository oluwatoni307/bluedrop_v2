// features/user/services/user_db_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/database_service.dart'; // Import your existing file

final userDbServiceProvider = Provider((ref) => UserDbService());

class UserDbService {
  // We use your EXISTING DatabaseService class
  final _db = DatabaseService();

  // Read Profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    return await _db.getProfile();
  }

  // Update Profile (Calls your existing updateProfile method)
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    await _db.updateProfile(updates);
  }
}
