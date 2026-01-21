import '../../../../services/database_service.dart';

class PersonaRepository {
  final DatabaseService _db = DatabaseService();

  Future<Map<String, String>> getPersona() async {
    final profile = await _db.getProfile();

    return {
      // 🔥 FIX: Changed 'name' to 'userName' to match HomeProvider
      'name': profile?['name'] ?? 'User',

      // These represent the AI Persona, ensure they match your DB save keys
      'tag': profile?['tag'] ?? 'Water Explorer',
      'bio': profile?['bio'] ?? 'Your journey starts today!',
    };
  }
}
