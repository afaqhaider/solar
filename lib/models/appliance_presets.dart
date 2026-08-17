class AppliancePreset {
  final String name;
  final double defaultWattage;

  const AppliancePreset(this.name, this.defaultWattage);
}

class AppliancePresets {
  static const List<AppliancePreset> list = [
    AppliancePreset("Air Conditioner", 1500.0),
    AppliancePreset("Refrigerator", 200.0),
    AppliancePreset("Ceiling Fan", 75.0),
    AppliancePreset("Television", 100.0),
    AppliancePreset("LED Light", 12.0),
    AppliancePreset("Washing Machine", 500.0),
    AppliancePreset("Water Pump", 750.0),
    AppliancePreset("Laptop", 65.0),
    AppliancePreset("Desktop Computer", 250.0),
    AppliancePreset("Microwave", 1200.0),
  ];
}
