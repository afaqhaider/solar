import 'dart:math';
import '../models/appliance.dart';
import '../models/solar_result.dart';

class SolarCalculator {
  static SolarResult calculate({
    required List<Appliance> appliances,
    required double peakSunHours,
    required double efficiency,
    required double panelWattage,
    required double backupHours,
    required double batteryVoltage,
    required double batteryAh,
    required double batteryDoD,
  }) {
    final totalLoad = appliances.fold<double>(0, (sum, item) => sum + (item.wattage * item.quantity));
    final dailyEnergy = appliances.fold<double>(0, (sum, item) => sum + item.dailyWh);

    final efficiencyFactor = efficiency / 100.0;
    final solarArrayW = (peakSunHours > 0 && efficiencyFactor > 0)
        ? dailyEnergy / peakSunHours / efficiencyFactor
        : 0.0;

    final panelCount = (panelWattage > 0)
        ? (solarArrayW / panelWattage).ceil()
        : 0;

    final minInverterSize = totalLoad / 0.80;

    final batteryBackupEnabled = backupHours > 0;
    double backupEnergyWh = 0.0;
    double usableBatteryWh = 0.0;
    int batteryCount = 0;

    if (batteryBackupEnabled) {
      backupEnergyWh = totalLoad * backupHours;
      usableBatteryWh = batteryVoltage * batteryAh * (batteryDoD / 100.0);
      if (usableBatteryWh > 0) {
        batteryCount = (backupEnergyWh / usableBatteryWh).ceil();
      }
    }

    return SolarResult(
      totalConnectedLoadW: totalLoad,
      dailyEnergyWh: dailyEnergy,
      peakSunHours: peakSunHours,
      requiredSolarArrayW: solarArrayW,
      panelWattage: panelWattage,
      panelCount: panelCount,
      installedSolarCapacityW: panelCount * panelWattage,
      minInverterCapacityW: minInverterSize,
      batteryBackupEnabled: batteryBackupEnabled,
      backupHours: backupHours,
      backupEnergyWh: backupEnergyWh,
      batteryVoltage: batteryVoltage,
      batteryAh: batteryAh,
      usableCapacityPerBatteryWh: usableBatteryWh,
      batteryCount: batteryCount,
    );
  }
}
