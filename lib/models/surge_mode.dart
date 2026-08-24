/// How simultaneous appliance startup/surge draw is estimated for inverter
/// planning. Both are estimates, never a guarantee of real-world behavior.
enum SurgeMode {
  /// Assumes typically only the single largest motor load starts at once.
  standard,

  /// Assumes relevant startup loads may overlap — a more cautious estimate.
  conservative;

  String get label => this == SurgeMode.standard
      ? 'Standard Estimate'
      : 'Conservative Estimate';

  String get description {
    switch (this) {
      case SurgeMode.standard:
        return 'Uses a reasonable calculated peak, assuming appliance startups are staggered rather than simultaneous.';
      case SurgeMode.conservative:
        return 'Assumes relevant startup loads may overlap — a more cautious, higher estimate.';
    }
  }

  static SurgeMode fromName(String? name) {
    return SurgeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => SurgeMode.standard,
    );
  }
}
