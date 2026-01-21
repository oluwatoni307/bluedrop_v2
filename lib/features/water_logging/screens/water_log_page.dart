import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../water_log.dart';
import '../water_logs_provider.dart';
import '../water_widgets.dart';

class WaterLogPage extends ConsumerStatefulWidget {
  const WaterLogPage({super.key});

  @override
  ConsumerState<WaterLogPage> createState() => _WaterLogPageState();
}

class _WaterLogPageState extends ConsumerState<WaterLogPage> {
  // Track which preset buttons are currently processing to prevent double-taps
  final Set<String> _processingPresets = {};

  // Track single-instance operations
  bool _isProcessingCustom = false;

  @override
  void dispose() {
    // Clean up processing state
    _processingPresets.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(waterLogsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Water Logging'),
        centerTitle: true,
      ),
      body: stateAsync.when(
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(waterLogsProvider.notifier).refresh(),
          notificationPredicate: (notification) {
            // Prevent accidental triggers during gestures/navigation
            return notification.depth == 0;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Quick Add Section
              _buildQuickAddSection(context, ref, state.presets),
              const SizedBox(height: 24),

              // More Options Section
              _buildMoreOptionsSection(context, ref),
              const SizedBox(height: 24),

              // Today's Logs Section
              _buildLogsSection(context, ref, state.logs),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(waterLogsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a success SnackBar with consistent styling
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an error SnackBar with retry action
  void _showErrorSnackBar(String message, VoidCallback onRetry) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }

  void _handleQuickAdd(WaterPreset preset) {
    // 1. Prevent duplicate taps
    if (_processingPresets.contains(preset.id)) return;

    // 2. Mark as processing
    setState(() => _processingPresets.add(preset.id));

    // 3. Fire-and-forget: Call provider (no await)
    ref
        .read(waterLogsProvider.notifier)
        .logWater(preset.amount, preset.drinkType)
        .then((_) {
          // Success callback
          if (!mounted) return;
          _showSuccessSnackBar('Logged ${preset.amount}ml ${preset.drinkType}');
        })
        .catchError((error) {
          // Error callback
          if (!mounted) return;
          _showErrorSnackBar(
            'Failed to save log',
            () => _handleQuickAdd(preset), // Retry with same preset
          );
        })
        .whenComplete(() {
          // Always re-enable button
          if (!mounted) return;
          setState(() => _processingPresets.remove(preset.id));
        });
  }

  void _handleCustomLog(int amount, String type) {
    // 1. Prevent duplicate submissions
    if (_isProcessingCustom) return;

    // 2. Mark as processing
    setState(() => _isProcessingCustom = true);

    // 3. Fire-and-forget
    ref
        .read(waterLogsProvider.notifier)
        .logWater(amount, type)
        .then((_) {
          if (!mounted) return;
          _showSuccessSnackBar('Logged ${amount}ml $type');
        })
        .catchError((error) {
          if (!mounted) return;
          _showErrorSnackBar(
            'Failed to save log',
            () => _handleCustomLog(amount, type),
          );
        })
        .whenComplete(() {
          if (!mounted) return;
          setState(() => _isProcessingCustom = false);
        });
  }

  void _handleDelete(String logId) {
    // Fire-and-forget with error handling
    ref
        .read(waterLogsProvider.notifier)
        .deleteLog(logId)
        .then((_) {
          if (!mounted) return;
          _showSuccessSnackBar('Log deleted');
        })
        .catchError((error) {
          if (!mounted) return;
          _showErrorSnackBar(
            'Failed to delete log',
            () => _handleDelete(logId),
          );
        });
  }

  Widget _buildQuickAddSection(
    BuildContext context,
    WidgetRef ref,
    List<WaterPreset> presets,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Add',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () async {
                await context.push('/presets');
              },
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Customize'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (presets.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No presets available. Tap Customize to add some!',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Column(
            children: [
              QuickAddButtons(
                presets: presets,
                onTap: _handleQuickAdd,
                processingPresets: _processingPresets,
              ),
              if (presets.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe for more',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildMoreOptionsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More Options',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                icon: Icons.calculate,
                label: 'Custom',
                onTap: () async {
                  final result = await context.push('/custom-log');

                  if (result != null && result is Map) {
                    final amount = result['amount'] as int?;
                    final type = result['type'] as String?;

                    if (amount != null && type != null && mounted) {
                      _handleCustomLog(amount, type);
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: ImageAnalysisButton()),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionCard(
                icon: Icons.list,
                label: 'Presets',
                onTap: () async {
                  await context.push('/presets');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogsSection(
    BuildContext context,
    WidgetRef ref,
    List<WaterLog> logs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Logs",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LogsList(logs: logs, onDelete: _handleDelete),
      ],
    );
  }
}
