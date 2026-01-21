import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import 'water_log.dart';

part 'water_logs_provider.g.dart';

// ========== STATE CLASSES ==========

class WaterLoggingState {
  final List<WaterLog> logs;
  final List<WaterPreset> presets;
  final bool isLoading;
  final String? errorMessage;

  WaterLoggingState({
    required this.logs,
    required this.presets,
    this.isLoading = false,
    this.errorMessage,
  });

  WaterLoggingState copyWith({
    List<WaterLog>? logs,
    List<WaterPreset>? presets,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WaterLoggingState(
      logs: logs ?? this.logs,
      presets: presets ?? this.presets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ========== PROVIDER ==========

@riverpod
class WaterLogs extends _$WaterLogs {
  @override
  Future<WaterLoggingState> build() async {
    // Load both logs and presets on init
    final logs = await _loadTodayLogs();
    final presets = await _loadPresets();

    return WaterLoggingState(logs: logs, presets: presets);
  }

  // ========== PRIVATE HELPERS ==========

  Future<List<WaterLog>> _loadTodayLogs() async {
    final db = DatabaseService();
    final List<Map<String, dynamic>> data = await db.getAllFromCollection(
      'waterLogs',
    );

    // Filter for today's logs only
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return data
        .map((json) => WaterLog.fromJson(json))
        .where((log) => log.date == today)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
  }

  Future<List<WaterPreset>> _loadPresets() async {
    final db = DatabaseService();

    try {
      final userData = await db.getProfile();
      if (userData == null) {
        return DEFAULT_PRESETS
            .map((json) => WaterPreset.fromJson(json))
            .toList();
      }

      final presetsJson = userData['waterPresets'] as List?;

      if (presetsJson == null || presetsJson.isEmpty) {
        return DEFAULT_PRESETS
            .map((json) => WaterPreset.fromJson(json))
            .toList();
      }

      return presetsJson
          .map((json) => WaterPreset.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return DEFAULT_PRESETS.map((json) => WaterPreset.fromJson(json)).toList();
    }
  }

  // ========== WATER LOGGING METHODS (OPTIMIZED) ==========

  Future<void> logWater(int amount, String type) async {
    final currentState = state.value;
    if (currentState == null) return;

    final now = DateTime.now();
    final newLog = WaterLog(
      id: now.millisecondsSinceEpoch.toString(),
      amount: amount,
      drinkType: type,
      timestamp: now,
      date: DateFormat('yyyy-MM-dd').format(now),
    );

    // 1. OPTIMISTIC UPDATE: Update UI Immediately
    // We add the log to the local list instantly
    final updatedLogs = [newLog, ...currentState.logs];

    // Update state without triggering loading spinner
    state = AsyncData(currentState.copyWith(logs: updatedLogs));

    // 2. BACKGROUND: Save to DB
    try {
      final db = DatabaseService();
      await db.addToCollection('waterLogs', newLog.toJson());
      // No need to invalidate! The UI is already correct.
    } catch (e) {
      // 3. ROLLBACK ON ERROR
      // If DB fails, revert to the old list
      state = AsyncData(currentState);
      // Rethrow so UI can handle the error
      rethrow;
    }
  }

  Future<void> deleteLog(String logId) async {
    final currentState = state.value;
    if (currentState == null) return;

    // 1. OPTIMISTIC UPDATE: Remove from UI immediately
    // We create a new list excluding the deleted item
    final updatedLogs = currentState.logs.where((l) => l.id != logId).toList();

    // Update the state instantly so the UI doesn't flicker
    state = AsyncData(currentState.copyWith(logs: updatedLogs));

    // 2. BACKGROUND: Delete from DB
    try {
      final db = DatabaseService();
      await db.deleteFromCollection('waterLogs', logId);

      // ⚠️ CRITICAL: Do NOT call ref.invalidateSelf() here!
      // The UI is already correct. Calling it will cause the glitch.
    } catch (e) {
      // 3. ROLLBACK ON ERROR
      // If DB fails, put the item back (revert state)
      state = AsyncData(currentState);

      // Throw error so UI can show a snackbar
      throw Exception("Failed to delete");
    }
  }

  // ========== PRESET METHODS ==========
  // Kept these as standard async for now as they are less time-sensitive

  Future<void> addPreset(WaterPreset preset) async {
    final currentState = state.value;
    if (currentState == null) return;

    final currentPresets = currentState.presets;
    if (currentPresets.length >= MAX_PRESETS) {
      throw Exception('Maximum $MAX_PRESETS presets allowed');
    }

    final db = DatabaseService();
    final updatedPresets = [...currentPresets, preset];

    await db.updateProfile({
      'waterPresets': updatedPresets.map((p) => p.toJson()).toList(),
    });
    ref.invalidateSelf();
  }

  Future<void> updatePreset(String presetId, WaterPreset updatedPreset) async {
    final currentState = state.value;
    if (currentState == null) return;

    final presets = List<WaterPreset>.from(currentState.presets);
    final index = presets.indexWhere((p) => p.id == presetId);

    if (index == -1) throw Exception('Preset not found');

    presets[index] = updatedPreset;
    final db = DatabaseService();
    await db.updateProfile({
      'waterPresets': presets.map((p) => p.toJson()).toList(),
    });
    ref.invalidateSelf();
  }

  Future<void> deletePreset(String presetId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final presets = currentState.presets;
    if (presets.length <= 1) {
      throw Exception('Cannot delete last preset. At least one required.');
    }

    final updatedPresets = presets.where((p) => p.id != presetId).toList();
    final db = DatabaseService();
    await db.updateProfile({
      'waterPresets': updatedPresets.map((p) => p.toJson()).toList(),
    });
    ref.invalidateSelf();
  }

  Future<void> reorderPresets(List<WaterPreset> reorderedPresets) async {
    final db = DatabaseService();
    await db.updateProfile({
      'waterPresets': reorderedPresets.map((p) => p.toJson()).toList(),
    });
    ref.invalidateSelf();
  }

  // ========== UTILITY METHODS ==========

  int getTodayTotal() {
    final currentState = state.value;
    if (currentState == null) return 0;
    return currentState.logs.fold(0, (sum, log) => sum + log.amount);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
