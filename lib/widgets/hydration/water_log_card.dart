import 'package:flutter/material.dart';
import '../../models/water_log.dart';

class WaterLogCard extends StatelessWidget {
  final WaterLog log;
  final VoidCallback onDelete;

  const WaterLogCard({super.key, required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getIcon(log.drinkType),
        title: Text(
          '${log.amount.toInt()}ml',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatDrinkType(log.drinkType)} • ${_formatTime(log.timestamp)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Widget _getIcon(String drinkType) {
    switch (drinkType) {
      case 'water':
        return const Text('💧', style: TextStyle(fontSize: 28));
      case 'coffee':
        return const Text('☕', style: TextStyle(fontSize: 28));
      case 'tea':
        return const Text('🍵', style: TextStyle(fontSize: 28));
      case 'juice':
        return const Text('🧃', style: TextStyle(fontSize: 28));
      default:
        return const Icon(Icons.local_drink, size: 28);
    }
  }

  String _formatDrinkType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
