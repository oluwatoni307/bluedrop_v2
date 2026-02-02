import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class UserContainer {
  final String id;
  final String name; // "Office Mug"
  final int volume; // 350
  final String iconType; // "mug", "bottle", "glass" (Our internal keys)
  final DateTime createdAt;

  UserContainer({
    required this.id,
    required this.name,
    required this.volume,
    required this.iconType,
    required this.createdAt,
  });

  // --- FACTORY ---
  factory UserContainer.create({
    required String name,
    required int volume,
    required String iconType,
  }) {
    return UserContainer(
      id: const Uuid().v4(),
      name: name,
      volume: volume,
      iconType: iconType,
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
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserContainer.fromMap(Map<String, dynamic> map) {
    return UserContainer(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      volume: (map['volume'] as num?)?.toInt() ?? 0,
      iconType: map['iconType'] ?? 'cup', // Default fallback
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

  static IconData getIcon(String type) => map[type] ?? Icons.local_drink;
}
