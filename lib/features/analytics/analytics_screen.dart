import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'analytics_model.dart';
import 'analytics_provider.dart';
import 'components/analytics_bar_chart.dart';
import 'components/period_selector.dart';
import 'components/summary_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);

    // Header text helper
    String getDateRangeText() {
      if (state.period == TimePeriod.custom &&
          state.customStart != null &&
          state.customEnd != null) {
        return '${DateFormat('MMM d').format(state.customStart!)} - ${DateFormat('MMM d').format(state.customEnd!)}';
      }
      return DateFormat('MMMM d, y').format(DateTime.now());
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analysis'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(analyticsProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SCOPE SELECTOR
              ScopeSelector(
                selectedPeriod: state.period,
                onChanged: (period) {
                  if (period == TimePeriod.custom) {
                    _pickDateRange(context, ref);
                  } else {
                    ref.read(analyticsProvider.notifier).setPeriod(period);
                  }
                },
              ),
              const SizedBox(height: 24),

              // 2. MAIN CHART
              Container(
                height: 340,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Hydration Trend",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          getDateRangeText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: state.isLoading && state.chartData.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : state.chartData.isEmpty
                          ? const Center(child: Text("No data available"))
                          : HydrationBarChart(dataPoints: state.chartData),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. STATS GRID
              const Text(
                "Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (state.isLoading && state.summary.totalVolume == 0)
                const Center(child: CircularProgressIndicator())
              else
                SummaryGrid(summary: state.summary),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      ref
          .read(analyticsProvider.notifier)
          .setCustomRange(result.start, result.end);
    }
  }
}
