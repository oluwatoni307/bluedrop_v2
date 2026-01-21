class DrinkPreset {
  final String id;
  final String name;
  final double amount;
  final String icon;

  DrinkPreset({
    required this.id,
    required this.name,
    required this.amount,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'amount': amount, 'icon': icon};
  }

  factory DrinkPreset.fromJson(Map<String, dynamic> json) {
    return DrinkPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      icon: json['icon'] as String,
    );
  }

  DrinkPreset copyWith({
    String? id,
    String? name,
    double? amount,
    String? icon,
  }) {
    return DrinkPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      icon: icon ?? this.icon,
    );
  }

  @override
  String toString() {
    return 'DrinkPreset(id: $id, name: $name, amount: ${amount}ml, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrinkPreset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PresetState {
  final List<DrinkPreset> presets;
  final List<DrinkPreset> quickAddPresets;
  final bool isLoading;
  final String? errorMessage;

  PresetState({
    required this.presets,
    required this.quickAddPresets,
    required this.isLoading,
    this.errorMessage,
  });

  PresetState copyWith({
    List<DrinkPreset>? presets,
    List<DrinkPreset>? quickAddPresets,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      quickAddPresets: quickAddPresets ?? this.quickAddPresets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
