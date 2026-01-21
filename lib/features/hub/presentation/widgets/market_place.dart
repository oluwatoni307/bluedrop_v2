import 'package:flutter/material.dart';
import '../../data/challenge_model.dart';

class MarketplaceCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;

  const MarketplaceCard({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWater = challenge.type == ChallengeType.waterMain;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160, // Fixed width for horizontal scrolling
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isWater ? Colors.blue.shade50 : Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWater ? Icons.water_drop : Icons.directions_walk,
                color: isWater ? Colors.blue : Colors.purple,
                size: 20,
              ),
            ),
            const Spacer(),
            // Title
            Text(
              challenge.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            // Duration
            Text(
              "${challenge.durationDays} Days",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            // "View" Button visual
            Text(
              "View details →",
              style: TextStyle(
                color: isWater ? Colors.blue : Colors.purple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
