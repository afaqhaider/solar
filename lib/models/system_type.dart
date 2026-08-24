/// The overall solar system configuration being planned. Changes what the
/// workflow emphasizes — it does not perform jurisdiction-specific
/// grid-connection compliance checks.
enum SystemType {
  gridTied,
  hybrid,
  offGrid;

  String get label {
    switch (this) {
      case SystemType.gridTied:
        return 'Grid-Tied';
      case SystemType.hybrid:
        return 'Hybrid';
      case SystemType.offGrid:
        return 'Off-Grid';
    }
  }

  String get description {
    switch (this) {
      case SystemType.gridTied:
        return 'Primarily solar generation with utility grid availability. Battery storage is optional.';
      case SystemType.hybrid:
        return 'Solar generation with battery storage and utility grid as a backstop.';
      case SystemType.offGrid:
        return 'Solar generation with battery storage and no assumption of continuous utility grid support.';
    }
  }

  /// Whether a battery bank is a required part of the workflow for this
  /// system type (it can always still be configured either way).
  bool get batteryRequired => this != SystemType.gridTied;

  static SystemType fromName(String? name) {
    return SystemType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => SystemType.hybrid,
    );
  }
}
