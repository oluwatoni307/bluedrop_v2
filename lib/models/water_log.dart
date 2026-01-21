class WaterLog {
  final String id;
  final double amount;
  final String drinkType;
  final DateTime timestamp;

  WaterLog({
    required this.id,
    required this.amount,
    required this.drinkType,
    required this.timestamp,
  });

  // Convert to Map for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'drinkType': drinkType,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from Map (from database)
  factory WaterLog.fromJson(Map<String, dynamic> json) {
    return WaterLog(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      drinkType: json['drinkType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // Create a copy with modifications
  WaterLog copyWith({
    String? id,
    double? amount,
    String? drinkType,
    DateTime? timestamp,
  }) {
    return WaterLog(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      drinkType: drinkType ?? this.drinkType,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'WaterLog(id: $id, amount: ${amount}ml, type: $drinkType, time: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaterLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
