import 'package:flutter/material.dart';
import '../analytics_model.dart';

class SummaryGrid extends StatelessWidget {
  final AnalyticsSummary summary;

  const SummaryGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildCard(
          title: "Avg Intake",
          value: "${summary.dailyAverage.toInt()} ml",
          icon: Icons.water_drop,
          color: Colors.blue,
        ),
        _buildCard(
          title: "Completion",
          value: "${(summary.completionRate * 100).toInt()}%",
          icon: Icons.flag,
          color: Colors.orange,
        ),
        _buildCard(
          title: "Total",
          value: "${(summary.totalVolume / 1000).toStringAsFixed(1)} L",
          icon: Icons.bar_chart,
          color: Colors.purple,
        ),
        _buildTrendCard(),
      ],
    );
  }

  Widget _buildTrendCard() {
    final isUp = summary.trendUp;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUp
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUp
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                color: isUp ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Trend",
                style: TextStyle(
                  color: isUp ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${isUp ? '+' : '-'}${summary.trendPercent.toStringAsFixed(1)}%",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            "vs last period",
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
