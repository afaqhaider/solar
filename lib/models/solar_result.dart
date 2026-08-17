class SolarResult {
  final double totalConnectedLoadW;
  final double dailyEnergyWh;
  final double peakSunHours;

  // Solar Panel Info
  final double requiredSolarArrayW;
  final double panelWattage;
  final int panelCount;
  final double installedSolarCapacityW;

  // Inverter Info
  final double minInverterCapacityW;

  // Battery Info
  final bool batteryBackupEnabled;
  final double backupHours;
  final double backupEnergyWh;
  final double batteryVoltage;
  final double batteryAh;
  final double usableCapacityPerBatteryWh;
  final int batteryCount;

  SolarResult({
    this.totalConnectedLoadW = 0.0,
    this.dailyEnergyWh = 0.0,
    this.peakSunHours = 0.0,
    this.requiredSolarArrayW = 0.0,
    this.panelWattage = 0.0,
    this.panelCount = 0,
    this.installedSolarCapacityW = 0.0,
    this.minInverterCapacityW = 0.0,
    this.batteryBackupEnabled = false,
    this.backupHours = 0.0,
    this.backupEnergyWh = 0.0,
    this.batteryVoltage = 0.0,
    this.batteryAh = 0.0,
    this.usableCapacityPerBatteryWh = 0.0,
    this.batteryCount = 0,
  });
}
