import 'package:intl/intl.dart';

// ========== WATER LOG MODEL ==========

class WaterLog {
  final String id;
  final int amount; // ml
  final String drinkType; // water/tea/coffee/juice/others
  final DateTime timestamp;
  final String date; // YYYY-MM-DD

  WaterLog({
    required this.id,
    required this.amount,
    required this.drinkType,
    required this.timestamp,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'drinkType': drinkType,
    'timestamp': timestamp.toIso8601String(),
    'date': date,
  };

  factory WaterLog.fromJson(Map<String, dynamic> json) => WaterLog(
    id: json['id'] as String,
    amount: json['amount'] as int,
    drinkType: json['drinkType'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    date: json['date'] as String,
  );

  // Format timestamp for display
  String get formattedTime => DateFormat('h:mm a').format(timestamp);

  // Get drink icon
  String get drinkIcon {
    switch (drinkType.toLowerCase()) {
      case 'water':
        return '💧';
      case 'tea':
        return '🍵';
      case 'coffee':
        return '☕';
      case 'juice':
        return '🧃';
      case 'others':
        return '🥤';
      default:
        return '💧';
    }
  }
}

// ========== WATER PRESET MODEL ==========

class WaterPreset {
  final String id;
  final String label;
  final int amount; // ml
  final String drinkType; // water/tea/coffee/juice/others

  WaterPreset({
    required this.id,
    required this.label,
    required this.amount,
    required this.drinkType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'amount': amount,
    'drinkType': drinkType,
  };

  factory WaterPreset.fromJson(Map<String, dynamic> json) => WaterPreset(
    id: json['id'] as String,
    label: json['label'] as String,
    amount: json['amount'] as int,
    drinkType: json['drinkType'] as String,
  );

  // Get drink icon
  String get icon {
    switch (drinkType.toLowerCase()) {
      case 'water':
        return '💧';
      case 'tea':
        return '🍵';
      case 'coffee':
        return '☕';
      case 'juice':
        return '🧃';
      case 'others':
        return '🥤';
      default:
        return '💧';
    }
  }
}

// ========== CONSTANTS ==========

const int MAX_PRESETS = 15;

const List<Map<String, dynamic>> DEFAULT_PRESETS = [
  {'id': 'default_1', 'label': '250ml', 'amount': 250, 'drinkType': 'water'},
  {'id': 'default_2', 'label': '500ml', 'amount': 500, 'drinkType': 'water'},
  {'id': 'default_3', 'label': '750ml', 'amount': 750, 'drinkType': 'water'},
  {'id': 'default_4', 'label': '1L', 'amount': 1000, 'drinkType': 'water'},
];

// ========== DRINK TYPE OPTIONS ==========

const List<String> DRINK_TYPES = ['water', 'tea', 'coffee', 'juice', 'others'];

const Map<String, String> DRINK_TYPE_LABELS = {
  'water': 'Water',
  'tea': 'Tea',
  'coffee': 'Coffee',
  'juice': 'Juice',
  'others': 'Others',
};
