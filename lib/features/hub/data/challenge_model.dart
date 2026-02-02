// features/hub/data/challenge_model.dart

enum ChallengeType {
  waterMain, // Replaces daily goal (Max 1)
  habitSide, // Yes/No daily toggle (Unlimited)
}

enum ChallengeStatus {
  available, // In the "Marketplace"
  active, // In the "Dashboard"
  completed, // In History
}

class Challenge {
  final String id;
  final String title;
  final String description; // Short summary
  final String detailsMarkdown; // Full instructions & benefits

  final ChallengeType type;
  final int durationDays;
  final int targetVolume; // For WaterMain (e.g., 3000ml)

  // State Tracking
  final ChallengeStatus status;
  final DateTime? startDate;
  final List<DateTime>
  completedDates; // For HabitSide: Tracks which days "Yes" was clicked

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.detailsMarkdown,
    required this.type,
    required this.durationDays,
    required this.targetVolume,
    this.status = ChallengeStatus.available,
    this.startDate,
    this.completedDates = const [],
  });

  /// Check if Habit is done TODAY
  bool get isHabitDoneToday {
    if (completedDates.isEmpty) return false;
    final last = completedDates.last;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  /// Create a copy of this object with updated fields (Immutable)
  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    String? detailsMarkdown,
    ChallengeType? type,
    int? durationDays,
    int? targetVolume,
    ChallengeStatus? status,
    DateTime? startDate,
    List<DateTime>? completedDates,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      detailsMarkdown: detailsMarkdown ?? this.detailsMarkdown,
      type: type ?? this.type,
      durationDays: durationDays ?? this.durationDays,
      targetVolume: targetVolume ?? this.targetVolume,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  // ---------------------------------------------------------------------------
  // SERIALIZATION
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'detailsMarkdown': detailsMarkdown,
      'type': type.index, // Storing as INT locally
      'durationDays': durationDays,
      'targetVolume': targetVolume,
      'status': status.index, // Storing as INT locally
      'startDate': startDate?.toIso8601String(),
      'completedDates': completedDates.map((e) => e.toIso8601String()).toList(),
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id']?.toString() ?? 'unknown_id',
      title: map['title'] ?? 'Untitled Challenge',
      description: map['description'] ?? '',
      detailsMarkdown: map['detailsMarkdown'] ?? '',

      // FIX 1: Robust Enum Parsing (Handles both 0 and "waterMain")
      type: _parseChallengeType(map['type']),

      // FIX 2: Robust Status Parsing (Handles both 0 and "available")
      status: _parseChallengeStatus(map['status']),

      // FIX 3: Robust Int Parsing (Handles "7" string from JSON)
      durationDays: int.tryParse(map['durationDays'].toString()) ?? 1,
      targetVolume: int.tryParse(map['targetVolume'].toString()) ?? 0,

      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'])
          : null,
      completedDates:
          (map['completedDates'] as List?)
              ?.map((e) => DateTime.parse(e))
              .toList() ??
          [],
    );
  }

  // --- Helper Methods for Safe Parsing ---

  static ChallengeType _parseChallengeType(dynamic input) {
    // 1. Handle Integer (from local DB or strict API)
    if (input is int) {
      return ChallengeType.values.length > input
          ? ChallengeType.values[input]
          : ChallengeType.habitSide;
    }
    // 2. Handle String (from loose AI JSON)
    if (input is String) {
      if (input == 'waterMain') return ChallengeType.waterMain;
      if (input == 'habitSide') return ChallengeType.habitSide;
    }
    // 3. Fallback
    return ChallengeType.habitSide;
  }

  static ChallengeStatus _parseChallengeStatus(dynamic input) {
    // 1. Handle Integer
    if (input is int) {
      return ChallengeStatus.values.length > input
          ? ChallengeStatus.values[input]
          : ChallengeStatus.available;
    }
    // 2. Handle String
    if (input is String) {
      if (input == 'active') return ChallengeStatus.active;
      if (input == 'completed') return ChallengeStatus.completed;
      if (input == 'available') return ChallengeStatus.available;
    }
    // 3. Fallback
    return ChallengeStatus.available;
  }

  // ---------------------------------------------------------------------------
  // LOGIC
  // ---------------------------------------------------------------------------

  /// Calculate Timeline Progress (0.0 to 1.0) based on DURATION
  double getTimelineProgress() {
    if (startDate == null) return 0.0;

    final now = DateTime.now();
    // Total duration in minutes (for smoother progress bars than just days)
    final totalMinutes = durationDays * 24 * 60;
    final elapsedMinutes = now.difference(startDate!).inMinutes;

    if (totalMinutes == 0) return 0.0;

    return (elapsedMinutes / totalMinutes).clamp(0.0, 1.0);
  }
}
