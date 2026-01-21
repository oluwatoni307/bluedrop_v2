import 'package:flutter/material.dart';

class DrinkTypeDistribution extends StatelessWidget {
  final Map<String, double> distribution;

  const DrinkTypeDistribution({
    Key? key,
    required this.distribution,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No drink type data'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💧 Drink Type Distribution',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              return _DistributionBar(
                label: _formatDrinkType(entry.key),
                percentage: entry.value,
                color: _getDrinkTypeColor(entry.key, context),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatDrinkType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  Color _getDrinkTypeColor(String type, BuildContext context) {
    switch (type.toLowerCase()) {
      case 'water':
        return Colors.blue;
      case 'tea':
        return Colors.brown;
      case 'coffee':
        return Colors.brown.shade800;
      case 'juice':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
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
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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