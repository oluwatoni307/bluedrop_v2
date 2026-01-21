import 'package:flutter/material.dart';

class TimeDistribution extends StatelessWidget {
  final Map<String, double> distribution;

  const TimeDistribution({Key? key, required this.distribution})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No time distribution data'),
        ),
      );
    }

    // Order by time of day
    final orderedTimes = ['morning', 'afternoon', 'evening', 'night'];
    final orderedDistribution = {
      for (var time in orderedTimes)
        if (distribution.containsKey(time)) time: distribution[time]!,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⏰ Best Logging Times',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...orderedDistribution.entries.map((entry) {
              return _DistributionBar(
                label: _formatTimeLabel(entry.key),
                percentage: entry.value,
                color: _getTimeColor(entry.key),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatTimeLabel(String time) {
    switch (time) {
      case 'morning':
        return 'Morning (6am-12pm)';
      case 'afternoon':
        return 'Afternoon (12pm-6pm)';
      case 'evening':
        return 'Evening (6pm-12am)';
      case 'night':
        return 'Night (12am-6am)';
      default:
        return time[0].toUpperCase() + time.substring(1);
    }
  }

  Color _getTimeColor(String time) {
    switch (time) {
      case 'morning':
        return Colors.amber;
      case 'afternoon':
        return Colors.orange;
      case 'evening':
        return Colors.deepPurple;
      case 'night':
        return Colors.indigo.shade900;
      default:
        return Colors.blue;
    }
  }
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _DistributionBar({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
