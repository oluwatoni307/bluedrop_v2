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

  // SERIALIZATION (For Hive/Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'detailsMarkdown': detailsMarkdown,
      'type': type.index,
      'durationDays': durationDays,
      'targetVolume': targetVolume,
      'status': status.index,
      'startDate': startDate?.toIso8601String(),
      'completedDates': completedDates.map((e) => e.toIso8601String()).toList(),
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      detailsMarkdown: map['detailsMarkdown'] ?? '',
      type: ChallengeType.values[map['type']],
      durationDays: map['durationDays'],
      targetVolume: map['targetVolume'],
      status: ChallengeStatus.values[map['status']],
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : null,
      completedDates:
          (map['completedDates'] as List?)
              ?.map((e) => DateTime.parse(e))
              .toList() ??
          [],
    );
  }

  /// Calculate Timeline Progress (0.0 to 1.0) based on DURATION
  double getTimelineProgress() {
    if (startDate == null) return 0.0;

    final now = DateTime.now();
    final _ = startDate!.add(Duration(days: durationDays));

    // Total duration in minutes (for smoother progress bars than just days)
    final totalMinutes = durationDays * 24 * 60;
    final elapsedMinutes = now.difference(startDate!).inMinutes;

    if (totalMinutes == 0) return 0.0;

    return (elapsedMinutes / totalMinutes).clamp(0.0, 1.0);
  }
}
