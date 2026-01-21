import 'package:flutter/material.dart';
import '../../models/drink_preset.dart';

class QuickAddButtons extends StatelessWidget {
  final List<DrinkPreset> presets;
  final Function(DrinkPreset) onPresetTap;

  const QuickAddButtons({
    super.key,
    required this.presets,
    required this.onPresetTap,
  });

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No quick add presets configured',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: presets.map((preset) {
        return _buildPresetButton(preset);
      }).toList(),
    );
  }

  Widget _buildPresetButton(DrinkPreset preset) {
    return ElevatedButton(
      onPressed: () => onPresetTap(preset),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(preset.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(preset.name, style: const TextStyle(fontSize: 12)),
          Text(
            '${preset.amount.toInt()}ml',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
