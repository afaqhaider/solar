/// Supported battery chemistries for planning purposes. Defaults are
/// common planning assumptions, not manufacturer specifications — every
/// value stays user-editable in the UI.
enum BatteryChemistry {
  leadAcid,
  agm,
  gel,
  lifepo4,
  custom;

  String get label {
    switch (this) {
      case BatteryChemistry.leadAcid:
        return 'Flooded Lead Acid';
      case BatteryChemistry.agm:
        return 'AGM';
      case BatteryChemistry.gel:
        return 'Gel';
      case BatteryChemistry.lifepo4:
        return 'LiFePO4';
      case BatteryChemistry.custom:
        return 'Custom';
    }
  }

  /// A typical planning depth-of-discharge (%), editable by the user.
  double get defaultDoDPercent {
    switch (this) {
      case BatteryChemistry.leadAcid:
        return 50;
      case BatteryChemistry.agm:
        return 60;
      case BatteryChemistry.gel:
        return 60;
      case BatteryChemistry.lifepo4:
        return 90;
      case BatteryChemistry.custom:
        return 80;
    }
  }

  /// A typical planning round-trip efficiency (%), editable by the user.
  double get defaultEfficiencyPercent {
    switch (this) {
      case BatteryChemistry.leadAcid:
        return 85;
      case BatteryChemistry.agm:
        return 90;
      case BatteryChemistry.gel:
        return 90;
      case BatteryChemistry.lifepo4:
        return 97;
      case BatteryChemistry.custom:
        return 90;
    }
  }

  static BatteryChemistry fromName(String? name) {
    return BatteryChemistry.values.firstWhere(
      (c) => c.name == name,
      orElse: () => BatteryChemistry.leadAcid,
    );
  }
}
