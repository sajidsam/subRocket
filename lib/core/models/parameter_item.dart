enum ParamCategory {
  battery(name: 'BATTERY & POWER', prefix: 'BATT_'),
  navigation(name: 'WAYPOINT & NAV', prefix: 'WPNAV_'),
  attitude(name: 'ATTITUDE & PID', prefix: 'ATC_'),
  failsafe(name: 'FAILSAFE & RTL', prefix: 'FS_'),
  motors(name: 'MOTORS & ESC', prefix: 'MOT_'),
  sensors(name: 'EKF & SENSORS', prefix: 'EK3_'),
  radio(name: 'RC & CHANNELS', prefix: 'RC'),
  system(name: 'SYSTEM & LOG', prefix: 'SYS_');

  const ParamCategory({required this.name, required this.prefix});
  final String name;
  final String prefix;
}

class ParameterItem {
  final String name;
  double value;
  final double defaultValue;
  final double min;
  final double max;
  final String unit;
  final String description;
  final ParamCategory category;
  bool isDirty;

  ParameterItem({
    required this.name,
    required this.value,
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.unit,
    required this.description,
    required this.category,
    this.isDirty = false,
  });

  ParameterItem copyWith({
    String? name,
    double? value,
    double? defaultValue,
    double? min,
    double? max,
    String? unit,
    String? description,
    ParamCategory? category,
    bool? isDirty,
  }) {
    return ParameterItem(
      name: name ?? this.name,
      value: value ?? this.value,
      defaultValue: defaultValue ?? this.defaultValue,
      min: min ?? this.min,
      max: max ?? this.max,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      category: category ?? this.category,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  void updateValue(double newValue) {
    value = newValue.clamp(min, max);
    isDirty = (value != defaultValue);
  }
}
