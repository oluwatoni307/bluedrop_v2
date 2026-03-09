import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../data/challenge_model.dart';
import '../../data/challenges_repository.dart';

class ChallengeDetailsPage extends StatefulWidget {
  final Challenge challenge;
  final int currentWaterLog; // Keeps the parameter you added

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

  Future<void> _handleJoin() async {
    setState(() => _isLoading = true);
    try {
      await _repo.joinChallenge(widget.challenge);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Challenge Accepted! 🌊")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLeave() async {
    // You can add a confirmation dialog here if you like
    setState(() => _isLoading = true);
    await _repo.leaveChallenge(widget.challenge);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isJoined = widget.challenge.status == ChallengeStatus.active;

    return Scaffold(
      appBar: AppBar(title: const Text("Challenge Details")),
      body: Column(
        children: [
          // 1. THE PERFORMANCE CARD
          if (isJoined) _buildPerformanceHeader(widget.challenge),

          // 2. The Markdown Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Meta
                  Text(
                    widget.challenge.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text("${widget.challenge.durationDays} Days Duration"),
                    ],
                  ),
                  const Divider(height: 30),

                  // Instructions
                  MarkdownBody(
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
                ],
              ),
            ),
          ),

          // 3. The Sticky Action Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (isJoined ? _handleLeave : _handleJoin),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined ? Colors.red.shade50 : Colors.blue,
                  foregroundColor: isJoined ? Colors.red : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isJoined ? 0 : 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isJoined ? "Give Up Challenge" : "Start Challenge",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // REBUILT: PERFORMANCE HEADER WIDGET
  // ============================================
  Widget _buildPerformanceHeader(Challenge challenge) {
    // 1. Calculate Timeline (Time Elapsed)
    final int daysElapsed =
        DateTime.now()
            .difference(challenge.startDate ?? DateTime.now())
            .inDays +
        1;
    final int currentDay = daysElapsed.clamp(1, challenge.durationDays);

    // 2. Calculate Completion (Actual Effort)
    final int completedCount = challenge.completedDates.length;

    // The progress bar reflects COMPLETION vs TOTAL DURATION
    final double completionProgress = (completedCount / challenge.durationDays)
        .clamp(0.0, 1.0);

    final isWater = challenge.type == ChallengeType.waterMain;
    final primaryColor = isWater ? Colors.blue : Colors.purple;
    final bgColor = isWater ? Colors.blue.shade50 : Colors.purple.shade50;

    return Container(
      width: double.infinity,
      color: bgColor.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Text(
            "YOUR PROGRESS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // THE STATS ROW: Time Elapsed vs Days Completed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Stat 1: The Timeline
              Column(
                children: [
                  Text(
                    "Day $currentDay",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    "of ${challenge.durationDays}",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // Divider
              Container(height: 40, width: 1, color: Colors.grey.shade300),

              // Stat 2: The Score (Completed Days)
              Column(
                children: [
                  Text(
                    "$completedCount",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    "Days Done",
                    style: TextStyle(fontSize: 14, color: primaryColor),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // PROGRESS BAR: Visualizing actual completion
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completionProgress,
                  backgroundColor: Colors.white,
                  color: primaryColor,
                  minHeight: 16,
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${(completionProgress * 100).toInt()}% Completed",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // SUBTEXT: Context specific info
          Text(
            isWater
                ? "Keep hitting your daily ${challenge.targetVolume}ml target!"
                : (challenge.isHabitDoneToday
                      ? "Great job today! 🎉"
                      : "Don't forget to check in today!"),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
