import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class UserContainer {
  final String id;
  final String name; // "Office Mug"
  final int volume; // 350
  final String iconType; // "mug", "bottle", "glass" (Our internal keys)
  final String? iconColor;
  final DateTime createdAt;

  UserContainer({
    required this.id,
    required this.name,
    required this.volume,
    required this.iconType,
    this.iconColor,
    required this.createdAt,
  });

  // --- FACTORY ---
  factory UserContainer.create({
    required String name,
    required int volume,
    required String iconType,
    String? iconColor,
  }) {
    return UserContainer(
      id: const Uuid().v4(),
      name: name,
      volume: volume,
      iconType: iconType,
      iconColor: iconColor,
      createdAt: DateTime.now(),
    );
  }

  // --- SERIALIZATION ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'volume': volume,
      'iconType': iconType,
      'iconColor': iconColor,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserContainer.fromMap(Map<String, dynamic> map) {
    return UserContainer(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      volume: (map['volume'] as num?)?.toInt() ?? 0,
      iconType: map['iconType'] ?? 'cup', // Default fallback
      iconColor: map['iconColor'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ContainerIcons {
  static const Map<String, IconData> map = {
    'bottle': Icons.local_drink, // Standard plastic bottle
    'bottle_metal': Icons.propane_tank_outlined, // Resembles a thermos/flask
    'mug': Icons.coffee, // Coffee mug
    'glass': Icons.local_bar, // Glass
    'cup': Icons.local_cafe, // Paper cup
    'jug': Icons.kitchen, // Large jug
  };

  static const Map<String, Color> colors = {
    'bottle': Color(0xFF2F80ED),
    'bottle_metal': Color(0xFF65758B),
    'mug': Color(0xFFB5651D),
    'glass': Color(0xFF00A6A6),
    'cup': Color(0xFFE09F3E),
    'jug': Color(0xFF7B61A8),
  };

  static IconData getIcon(String type) => map[type] ?? Icons.local_drink;

  static Color getColor(String type, [String? colorHex]) {
    if (colorHex != null) {
      final normalized = colorHex.replaceFirst('#', '');
      final value = normalized.length == 6 ? 'FF$normalized' : normalized;
      final colorValue = int.tryParse(value, radix: 16);
      if (colorValue != null) return Color(colorValue);
    }
    return colors[type] ?? const Color(0xFF2F80ED);
  }
}
