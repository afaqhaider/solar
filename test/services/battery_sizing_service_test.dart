import 'package:flutter_test/flutter_test.dart';
import 'package:solar/models/design_status.dart';
import 'package:solar/services/battery_sizing_service.dart';

void main() {
  const service = BatterySizingService();

  test('backup disabled when backupHours is 0', () {
    final result = service.computeBankSizing(
      essentialLoadW: 500,
      backupHours: 0,
      unitVoltage: 12,
      unitAh: 100,
      seriesCount: 1,
      parallelCount: 4,
      dodPercent: 50,
      batteryEfficiencyPercent: 85,
    );
    expect(result.backupEnabled, false);
    expect(result.status, DesignStatus.configurationIncomplete);
  });

  test('nominal and usable bank energy for a single 12V 100Ah battery', () {
    final result = service.computeBankSizing(
      essentialLoadW: 100,
      backupHours: 2,
      unitVoltage: 12,
      unitAh: 100,
      seriesCount: 1,
      parallelCount: 1,
      dodPercent: 50,
      batteryEfficiencyPercent: 90,
    );
    // nominal = 12V * 100Ah = 1200 Wh
    expect(result.nominalBankWh, closeTo(1200, 0.001));
    // usable = 1200 * 0.5 * 0.9 = 540 Wh
    expect(result.usableBankWh, closeTo(540, 0.001));
  });

  test('series wiring increases bank voltage, Ah unchanged', () {
    final result = service.computeBankSizing(
      essentialLoadW: 100,
      backupHours: 1,
      unitVoltage: 12,
      unitAh: 100,
      seriesCount: 4, // 4x 12V in series -> 48V
      parallelCount: 1,
      dodPercent: 100,
      batteryEfficiencyPercent: 100,
    );
    expect(result.bankVoltage, closeTo(48, 0.001));
    expect(result.bankAh, closeTo(100, 0.001));
  });

  test('parallel wiring increases bank Ah, voltage unchanged', () {
    final result = service.computeBankSizing(
      essentialLoadW: 100,
      backupHours: 1,
      unitVoltage: 12,
      unitAh: 100,
      seriesCount: 1,
      parallelCount: 3, // 3x 100Ah in parallel -> 300Ah
      dodPercent: 100,
      batteryEfficiencyPercent: 100,
    );
    expect(result.bankVoltage, closeTo(12, 0.001));
    expect(result.bankAh, closeTo(300, 0.001));
  });

  test(
    'required usable energy scales with load, backup hours and design reserve',
    () {
      final result = service.computeBankSizing(
        essentialLoadW: 200,
        backupHours: 4,
        unitVoltage: 12,
        unitAh: 100,
        seriesCount: 1,
        parallelCount: 1,
        dodPercent: 50,
        batteryEfficiencyPercent: 90,
        designReservePercent: 25,
      );
      // required usable = 200W * 4h * 1.25 = 1000 Wh
      expect(result.requiredUsableWh, closeTo(1000, 0.001));
      // required nominal = 1000 / 0.5 / 0.9 = 2222.2 Wh
      expect(result.requiredNominalWh, closeTo(2222.22, 0.1));
    },
  );

  test('recommends enough parallel strings to cover the requirement', () {
    final result = service.computeBankSizing(
      essentialLoadW: 500,
      backupHours: 4,
      unitVoltage: 12,
      unitAh: 100,
      seriesCount: 1,
      parallelCount: 1,
      dodPercent: 50,
      batteryEfficiencyPercent: 100,
    );
    // required usable = 500*4 = 2000 Wh; required nominal = 2000/0.5 = 4000 Wh
    // per-unit nominal = 12*100 = 1200 Wh -> ceil(4000/1200) = 4 strings
    expect(result.recommendedParallelCount, 4);
  });

  test('status is shortfall when configured bank is under the requirement', () {
    final result = service.computeBankSizing(
      essentialLoadW: 500,
      backupHours: 8,
      unitVoltage: 12,
      unitAh: 100,
      seriesCount: 1,
      parallelCount: 1, // clearly undersized for 8h at 500W
      dodPercent: 50,
      batteryEfficiencyPercent: 90,
    );
    expect(result.status, DesignStatus.capacityShortfall);
    expect(result.surplusUsableWh, lessThan(0));
  });

  test(
    'status is meetsSelectedTarget when configured bank closely matches the requirement',
    () {
      // required usable = 500*4 = 2000 Wh; required nominal = 2000/0.5/0.9 ≈ 4444 Wh
      // 4 x 1200Wh units (parallel) = 4800 Wh nominal -> usable = 4800*0.5*0.9 = 2160 Wh (within 15%)
      final result = service.computeBankSizing(
        essentialLoadW: 500,
        backupHours: 4,
        unitVoltage: 12,
        unitAh: 100,
        seriesCount: 1,
        parallelCount: 4,
        dodPercent: 50,
        batteryEfficiencyPercent: 90,
      );
      expect(result.status, DesignStatus.meetsSelectedTarget);
    },
  );

  test(
    'status is additionalReserveAvailable when bank far exceeds the requirement',
    () {
      final result = service.computeBankSizing(
        essentialLoadW: 100,
        backupHours: 1,
        unitVoltage: 12,
        unitAh: 100,
        seriesCount: 1,
        parallelCount: 10,
        dodPercent: 80,
        batteryEfficiencyPercent: 95,
      );
      expect(result.status, DesignStatus.additionalReserveAvailable);
      expect(result.surplusUsableWh, greaterThan(0));
    },
  );

  test('estimated runtime is usable energy divided by essential load', () {
    final result = service.computeBankSizing(
      essentialLoadW: 200,
      backupHours: 1,
      unitVoltage: 12,
      unitAh: 100,
      seriesCount: 1,
      parallelCount: 1,
      dodPercent: 50,
      batteryEfficiencyPercent: 100,
    );
    // usable = 12*100*0.5 = 600 Wh; runtime = 600/200 = 3h
    expect(result.estimatedRuntimeHours, closeTo(3, 0.001));
  });

  test(
    'boundary: zero essential load does not throw and yields zero runtime',
    () {
      final result = service.computeBankSizing(
        essentialLoadW: 0,
        backupHours: 4,
        unitVoltage: 12,
        unitAh: 100,
        seriesCount: 1,
        parallelCount: 1,
        dodPercent: 50,
        batteryEfficiencyPercent: 90,
      );
      expect(result.estimatedRuntimeHours, 0);
      expect(result.requiredUsableWh, 0);
    },
  );

  test('boundary: DoD and efficiency are clamped to a sane 0-100% range', () {
    final result = service.computeBankSizing(
      essentialLoadW: 100,
      backupHours: 1,
      unitVoltage: 12,
      unitAh: 100,
      seriesCount: 1,
      parallelCount: 1,
      dodPercent: 150, // invalid input, must not exceed 100%
      batteryEfficiencyPercent: 120, // invalid input, must not exceed 100%
    );
    expect(result.usableBankWh, closeTo(1200, 0.001)); // 100% DoD * 100% eff
  });
}
