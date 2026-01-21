import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../analytics_model.dart';
import '../analytics_provider.dart';

class InsightsCard extends ConsumerWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Just watch. The parent screen triggers the load.
    final state = ref.watch(analyticsProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => context.pushNamed('analytics'),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.insights,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Weekly Insights',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 20),

              // CONTENT
              if (state.isLoading && state.summary.totalVolume == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (state.error != null)
                Text(
                  'Could not load data',
                  style: TextStyle(color: theme.colorScheme.error),
                )
              else
                _buildStats(context, state.summary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, AnalyticsSummary summary) {
    final theme = Theme.of(context);
    final isTrendPositive = summary.trendUp;

    return Row(
      children: [
        // Left Stat: Daily Average
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Average',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${summary.dailyAverage.toInt()}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    ' ml',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Vertical Divider
        Container(height: 40, width: 1, color: Colors.grey[200]),
        const SizedBox(width: 20),

        // Right Stat: Trend
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trend',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isTrendPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTrendPositive ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: isTrendPositive
                          ? Colors.green[700]
                          : Colors.orange[800],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${summary.trendPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isTrendPositive
                            ? Colors.green[700]
                            : Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
