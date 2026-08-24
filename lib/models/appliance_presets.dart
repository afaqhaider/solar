/// A starting-point appliance definition. Values are common, editable
/// examples — not guaranteed manufacturer specifications.
class AppliancePreset {
  final String name;
  final String category;
  final double defaultWattage;
  final double? defaultSurgeWattage;
  final double defaultUsageHours;

  const AppliancePreset(
    this.name,
    this.category,
    this.defaultWattage, {
    this.defaultSurgeWattage,
    this.defaultUsageHours = 4,
  });
}

class AppliancePresets {
  static const List<AppliancePreset> list = [
    AppliancePreset('LED Light', 'Lighting', 12.0, defaultUsageHours: 6),
    AppliancePreset('Ceiling Fan', 'Comfort', 75.0, defaultUsageHours: 8),
    AppliancePreset(
      'Refrigerator',
      'Kitchen',
      200.0,
      defaultSurgeWattage: 600,
      defaultUsageHours: 24,
    ),
    AppliancePreset('Television', 'Entertainment', 100.0, defaultUsageHours: 4),
    AppliancePreset('Laptop', 'Office', 65.0, defaultUsageHours: 5),
    AppliancePreset('Desktop Computer', 'Office', 250.0, defaultUsageHours: 5),
    AppliancePreset(
      'Air Conditioner',
      'Comfort',
      1500.0,
      defaultSurgeWattage: 2200,
      defaultUsageHours: 6,
    ),
    AppliancePreset(
      'Water Pump',
      'Utility',
      750.0,
      defaultSurgeWattage: 1800,
      defaultUsageHours: 1,
    ),
    AppliancePreset(
      'Washing Machine',
      'Utility',
      500.0,
      defaultSurgeWattage: 1100,
      defaultUsageHours: 1,
    ),
    AppliancePreset('Microwave', 'Kitchen', 1200.0, defaultUsageHours: 0.5),
    AppliancePreset('Router', 'Office', 15.0, defaultUsageHours: 24),
    AppliancePreset('Custom Appliance', 'Custom', 0.0, defaultUsageHours: 1),
  ];
}
