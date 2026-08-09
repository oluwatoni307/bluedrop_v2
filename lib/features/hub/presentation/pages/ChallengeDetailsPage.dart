// ===========================================================================
// FILE: challenge_details_page.dart
// LAYER: Presentation
// DOMAIN: Goals / Challenges
// RESPONSIBILITY: Detail view for a single challenge. Shows progress header
//   when active (stable height regardless of join state), markdown
//   instructions, and a sticky CTA zone. Destructive "Leave challenge" action
//   is demoted to a text button above the primary CTA so the exit ramp is
//   never the dominant affordance on a return visit.
// CONNECTIONS:
//   - ChallengesRepository  → joinChallenge, leaveChallenge
//   - Challenge (model)     → all display data
//   - flutter_markdown      → detailsMarkdown rendering
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../data/challenge_model.dart';
import '../../data/challenges_repository.dart';

class ChallengeDetailsPage extends StatefulWidget {
  final Challenge challenge;
  final int currentWaterLog;

  const ChallengeDetailsPage({
    super.key,
    required this.challenge,
    required this.currentWaterLog,
  });

  @override
  State<ChallengeDetailsPage> createState() => _ChallengeDetailsPageState();
}

class _ChallengeDetailsPageState extends State<ChallengeDetailsPage> {
  final ChallengesRepository _repo = ChallengesRepository();
  bool _isLoading = false;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _handleJoin() async {
    setState(() => _isLoading = true);
    try {
      await _repo.joinChallenge(widget.challenge);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("You're in — good luck.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Couldn't join — try again.")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLeave() async {
    // Confirm before a destructive action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave this challenge?'),
        content: const Text(
          'Your progress will be lost. You can always start again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    await _repo.leaveChallenge(widget.challenge);
    if (mounted) Navigator.pop(context, true);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isJoined = widget.challenge.status == ChallengeStatus.active;

    return Scaffold(
      // AppBar title is the challenge name — not the generic "Challenge Details"
      appBar: AppBar(
        title: Text(
          widget.challenge.title,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // 1. PROGRESS SLOT — always present, height is always stable.
          //    Shows live progress when joined, a quiet teaser when not.
          //    Eliminates the layout jump between states.
          _buildProgressSlot(isJoined, widget.challenge),

          // 2. CONTENT — markdown instructions with minimum height so the
          //    sticky footer never floats halfway up on short content.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta row: duration
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.challenge.durationDays}-day challenge',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Markdown content — minimum height keeps footer grounded
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 200),
                    child: MarkdownBody(
                      data: widget.challenge.detailsMarkdown,
                      styleSheet: MarkdownStyleSheet(
                        h1: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        p: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. STICKY CTA ZONE
          //    When joined: primary = daily action, secondary = leave (demoted)
          //    When not joined: single primary = Start challenge
          _buildCtaZone(isJoined),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Progress slot
  // ---------------------------------------------------------------------------

  Widget _buildProgressSlot(bool isJoined, Challenge challenge) {
    if (isJoined) {
      return _buildActiveProgressHeader(challenge);
    }

    // Not joined — quiet teaser, same approximate height, no layout jump
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            'Join to track your progress',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProgressHeader(Challenge challenge) {
    final int daysElapsed =
        DateTime.now()
            .difference(challenge.startDate ?? DateTime.now())
            .inDays +
        1;
    final int currentDay = daysElapsed.clamp(1, challenge.durationDays);
    final int completedCount = challenge.completedDates.length;
    final double completionProgress = (completedCount / challenge.durationDays)
        .clamp(0.0, 1.0);

    final isWater = challenge.type == ChallengeType.waterMain;
    final primaryColor = isWater ? Colors.blue : Colors.purple;
    final bgColor = isWater ? Colors.blue.shade50 : Colors.purple.shade50;

    // Contextual milestone message — calculated from existing values,
    // replaces the in-bar "% Completed" label
    final String milestoneText = _milestoneMessage(
      completedCount: completedCount,
      totalDays: challenge.durationDays,
      isWater: isWater,
      targetVolume: challenge.targetVolume,
      isHabitDoneToday: challenge.isHabitDoneToday,
    );

    return Container(
      width: double.infinity,
      color: bgColor.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          // Stats row — readable as a sentence: "Timeline / Completed"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Timeline position
              Column(
                children: [
                  Text(
                    'Day $currentDay of ${challenge.durationDays}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Timeline',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),

              Container(height: 36, width: 1, color: Colors.grey.shade300),

              // Actual completion
              Column(
                children: [
                  Text(
                    '$completedCount ${completedCount == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress bar — no in-bar label, milestone message below
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionProgress,
              backgroundColor: Colors.white,
              color: primaryColor,
              minHeight: 12,
            ),
          ),

          const SizedBox(height: 10),

          // Milestone message replaces the "% Completed" in-bar label
          Text(
            milestoneText,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CTA zone
  // ---------------------------------------------------------------------------

  Widget _buildCtaZone(bool isJoined) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: isJoined ? _buildJoinedCta() : _buildUnjoinedCta(),
    );
  }

  /// Joined state: primary action is the daily task.
  /// Leave challenge is demoted to a text button above — accessible but not
  /// dominant. The user no longer sees an exit ramp as the main CTA every
  /// time they open their active challenge.
  Widget _buildJoinedCta() {
    final isWater = widget.challenge.type == ChallengeType.waterMain;
    final primaryLabel = isWater ? 'Log water' : 'Mark today done';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Destructive action — low contrast, text only, top of zone
        TextButton(
          onPressed: _isLoading ? null : _handleLeave,
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade500,
            padding: EdgeInsets.zero,
          ),
          child: const Text('Leave challenge', style: TextStyle(fontSize: 13)),
        ),

        const SizedBox(height: 8),

        // Primary CTA — the action the user can take right now
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    // Hook this to your daily log / check-in action.
                    // For water challenges this navigates to the water log entry.
                    // For habit challenges this calls toggleHabitForToday.
                    // Wired at the call site — not hardcoded here.
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    primaryLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Unjoined state: single primary CTA only.
  Widget _buildUnjoinedCta() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Start challenge',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  /// Returns a contextual milestone message calculated from existing model
  /// values. Replaces the generic "% Completed" in-bar label.
  String _milestoneMessage({
    required int completedCount,
    required int totalDays,
    required bool isWater,
    required int? targetVolume,
    required bool isHabitDoneToday,
  }) {
    if (completedCount == 0) {
      return 'Complete your first day to get started.';
    }

    final remaining = totalDays - completedCount;

    if (remaining == 0) return 'Challenge complete — well done.';
    if (remaining == 1) return 'One day left. Finish strong.';

    final halfway = totalDays ~/ 2;
    if (completedCount == halfway) return "Halfway there — keep going.";

    if (isWater && targetVolume != null) {
      return 'Your daily target: ${targetVolume}ml. $remaining days to go.';
    }

    if (!isWater) {
      return isHabitDoneToday
          ? 'Done for today. $remaining days remaining.'
          : 'Check in today to keep your streak alive.';
    }

    return '$remaining days remaining.';
  }
}
