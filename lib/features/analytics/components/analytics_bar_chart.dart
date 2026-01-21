import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../analytics_model.dart';

class HydrationBarChart extends StatelessWidget {
  final List<ChartDataPoint> dataPoints;

  const HydrationBarChart({super.key, required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) return const SizedBox();

    // --- 1. DYNAMIC STYLING ---
    // Month View (30 days) needs thinner bars; Week/Year can have thick bars.
    final bool isCrowded = dataPoints.length > 20;
    final double barWidth = isCrowded ? 6 : 16;
    final double borderRadius = isCrowded ? 2 : 6;

    // --- 2. CALCULATE MAX Y ---
    final double maxBarValue = dataPoints.fold(0.0, (prev, element) {
      final val = element.y;
      return val > prev ? val : prev;
    });

    final double maxY = maxBarValue * 1.2;
    final double targetY = dataPoints.first.goal;
    final double efficientMaxY = maxY > targetY ? maxY : targetY * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: efficientMaxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} ml',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          // --- 3. SMART BOTTOM LABELS ---
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dataPoints.length)
                  return const SizedBox();

                final point = dataPoints[index];

                // LOGIC: If crowded (Month view), only show every 5th day + the last day
                if (isCrowded) {
                  // Assuming label is "1", "2", "30"...
                  // Try parsing the label to see if it's a day number
                  final dayNum = int.tryParse(point.label);
                  if (dayNum != null) {
                    // Show 1, 5, 10, 15, 20, 25, 30
                    if (dayNum != 1 && dayNum % 5 != 0) {
                      return const SizedBox();
                    }
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    point.label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  '${(value / 1000).toStringAsFixed(1)}k',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),

        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: targetY,
              color: Colors.green.withOpacity(0.5),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                labelResolver: (line) => 'Goal',
                style: TextStyle(
                  color: Colors.green.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),

        barGroups: dataPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.y,
                color: data.isMet ? Colors.blue : Colors.blue.withOpacity(0.3),
                width: barWidth, // Use dynamic width
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(borderRadius),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: efficientMaxY,
                  color: Colors.grey.withOpacity(0.05),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
