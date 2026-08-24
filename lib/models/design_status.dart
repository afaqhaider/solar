/// Planning indicator shown next to a sizing result. Deliberately avoids
/// any language implying certification, safety approval or a guarantee —
/// this is a planning utility, not an engineering sign-off.
enum DesignStatus {
  configurationIncomplete,
  capacityShortfall,
  meetsSelectedTarget,
  additionalReserveAvailable;

  String get label {
    switch (this) {
      case DesignStatus.configurationIncomplete:
        return 'Configuration Incomplete';
      case DesignStatus.capacityShortfall:
        return 'Capacity Shortfall';
      case DesignStatus.meetsSelectedTarget:
        return 'Meets Selected Target';
      case DesignStatus.additionalReserveAvailable:
        return 'Additional Reserve Available';
    }
  }
}
