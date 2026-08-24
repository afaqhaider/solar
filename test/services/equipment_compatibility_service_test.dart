import 'package:flutter_test/flutter_test.dart';
import 'package:solar/models/compatibility_result.dart';
import 'package:solar/models/equipment_specs.dart';
import 'package:solar/services/equipment_compatibility_service.dart';

void main() {
  const service = EquipmentCompatibilityService();

  test('insufficient data when panel/inverter specs are missing', () {
    final checks = service.checkPanelsAgainstInverter(
      const PanelSpec(),
      const InverterSpec(),
    );
    expect(
      checks.every((c) => c.status == CompatibilityStatus.insufficientData),
      true,
    );
  });

  test('array power within inverter max PV input is flagged within limits', () {
    final checks = service.checkPanelsAgainstInverter(
      const PanelSpec(ratedPowerW: 400, quantity: 10), // 4000W array
      const InverterSpec(ratedOutputW: 5000, maxPvInputW: 6000),
    );
    final powerCheck = checks.firstWhere(
      (c) => c.title.contains('maximum PV input'),
    );
    expect(powerCheck.status, CompatibilityStatus.withinEnteredLimits);
  });

  test(
    'array power exceeding inverter max PV input is flagged outside limits',
    () {
      final checks = service.checkPanelsAgainstInverter(
        const PanelSpec(ratedPowerW: 400, quantity: 20), // 8000W array
        const InverterSpec(ratedOutputW: 5000, maxPvInputW: 6000),
      );
      final powerCheck = checks.firstWhere(
        (c) => c.title.contains('maximum PV input'),
      );
      expect(powerCheck.status, CompatibilityStatus.outsideEnteredLimits);
    },
  );

  test('battery bank voltage matching inverter DC input is within limits', () {
    final check = service.checkBatteryAgainstInverter(
      const BatteryEquipmentSpec(
        nominalVoltage: 12,
        seriesCount: 4,
        capacityAh: 100,
      ), // 48V bank
      const InverterSpec(ratedOutputW: 3000, dcInputVoltage: 48),
    );
    expect(check.status, CompatibilityStatus.withinEnteredLimits);
  });

  test('battery bank voltage far from inverter DC input is outside limits', () {
    final check = service.checkBatteryAgainstInverter(
      const BatteryEquipmentSpec(
        nominalVoltage: 12,
        seriesCount: 1,
        capacityAh: 100,
      ), // 12V bank
      const InverterSpec(ratedOutputW: 3000, dcInputVoltage: 48),
    );
    expect(check.status, CompatibilityStatus.outsideEnteredLimits);
  });

  test(
    'battery vs inverter is insufficient data without a DC input voltage',
    () {
      final check = service.checkBatteryAgainstInverter(
        const BatteryEquipmentSpec(nominalVoltage: 12, capacityAh: 100),
        const InverterSpec(ratedOutputW: 3000),
      );
      expect(check.status, CompatibilityStatus.insufficientData);
    },
  );
}
