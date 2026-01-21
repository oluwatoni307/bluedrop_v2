import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'water_log.dart';

// ========== 1. QUICK ADD BUTTONS ==========

class QuickAddButtons extends StatelessWidget {
  final List<WaterPreset> presets;
  final Function(WaterPreset) onTap;
  final Set<String> processingPresets;

  const QuickAddButtons({
    super.key,
    required this.presets,
    required this.onTap,
    this.processingPresets = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final preset = presets[index];
          final isProcessing = processingPresets.contains(preset.id);
          return _PresetButton(
            preset: preset,
            onTap: () => onTap(preset),
            isProcessing: isProcessing,
          );
        },
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final WaterPreset preset;
  final VoidCallback onTap;
  final bool isProcessing;

  const _PresetButton({
    required this.preset,
    required this.onTap,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isProcessing ? 0.6 : 1.0,
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(preset.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  preset.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== 2. LOGS LIST ==========

class LogsList extends StatelessWidget {
  final List<WaterLog> logs;
  final Function(String logId) onDelete;

  const LogsList({super.key, required this.logs, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No logs yet. Start hydrating!',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      children: logs.map((log) {
        return LogCard(log: log, onDelete: () => onDelete(log.id));
      }).toList(),
    );
  }
}

// ========== 3. LOG CARD ==========

class LogCard extends StatelessWidget {
  final WaterLog log;
  final VoidCallback onDelete;

  const LogCard({super.key, required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(log.drinkIcon, style: const TextStyle(fontSize: 32)),
        title: Text(
          '${log.amount}ml ${DRINK_TYPE_LABELS[log.drinkType] ?? log.drinkType}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(log.formattedTime),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete Log?'),
                content: Text('Remove ${log.amount}ml from today?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ========== 4. IMAGE ANALYSIS BUTTON (PLACEHOLDER) ==========

class ImageAnalysisButton extends StatelessWidget {
  const ImageAnalysisButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feature coming soon! 🚀'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.camera_alt, size: 32),
              SizedBox(height: 8),
              Text('Image', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
