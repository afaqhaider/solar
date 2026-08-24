import 'package:flutter_test/flutter_test.dart';
import 'package:solar/models/appliance.dart';
import 'package:solar/models/planning_inputs.dart';
import 'package:solar/services/system_recommendation_service.dart';

void main() {
  const service = SystemRecommendationService();

  test('builds a complete recommendation from appliances and inputs', () {
    final appliances = [
      Appliance(
        name: 'Fridge',
        wattage: 200,
        quantity: 1,
        usageHours: 24,
        backupRequired: true,
      ),
      Appliance(
        name: 'A/C',
        wattage: 1500,
        quantity: 1,
        usageHours: 4,
        backupRequired: false,
      ),
    ];
    const inputs = PlanningInputs(
      peakSunHours: 5,
      systemEfficiencyPercent: 80,
      designReservePercent: 20,
      panelWattage: 400,
      backupHours: 4,
      batteryUnitVoltage: 12,
      batteryUnitAh: 100,
      batterySeriesCount: 1,
      batteryParallelCount: 2,
      batteryDoD: 50,
      batteryEfficiencyPercent: 90,
      inverterHeadroomPercent: 20,
    );

    final rec = service.build(
      projectName: 'Test Project',
      appliances: appliances,
      inputs: inputs,
    );

    expect(rec.loadProfile.connectedLoadW, closeTo(1700, 0.001));
    expect(rec.essentialLoadProfile.connectedLoadW, closeTo(200, 0.001));
    expect(rec.solarArraySizing.panelCount, greaterThan(0));
    expect(rec.batterySizing.backupEnabled, true);
    expect(rec.batterySizing.bankVoltage, closeTo(12, 0.001));
    expect(rec.batterySizing.bankAh, closeTo(200, 0.001));
    expect(rec.inverterSizing.recommendedInverterW, greaterThan(0));
    expect(
      rec.energyBalance.dailyConsumptionWh,
      closeTo(rec.loadProfile.dailyEnergyWh, 0.001),
    );
  });

  test(
    'battery sizing prefers the essential load over the full connected load when configured',
    () {
      final appliances = [
        Appliance(
          name: 'Fridge',
          wattage: 200,
          quantity: 1,
          usageHours: 24,
          backupRequired: true,
        ),
        Appliance(
          name: 'A/C',
          wattage: 1500,
          quantity: 1,
          usageHours: 4,
          backupRequired: false,
        ),
      ];
      const inputs = PlanningInputs(
        backupHours: 4,
        batteryParallelCount: 1,
        designReservePercent: 0,
      );

      final rec = service.build(
        projectName: 'P',
        appliances: appliances,
        inputs: inputs,
      );

      // Battery sizing should be based on the 200W essential load, not the 1700W full load.
      expect(rec.batterySizing.requiredUsableWh, closeTo(200 * 4, 0.001));
    },
  );

  test(
    'falls back to full running load for battery sizing when nothing is marked essential',
    () {
      final appliances = [
        Appliance(
          name: 'Fridge',
          wattage: 200,
          quantity: 1,
          usageHours: 24,
          backupRequired: false,
        ),
      ];
      const inputs = PlanningInputs(backupHours: 2, designReservePercent: 0);

      final rec = service.build(
        projectName: 'P',
        appliances: appliances,
        inputs: inputs,
      );
      expect(rec.batterySizing.requiredUsableWh, closeTo(200 * 2, 0.001));
    },
  );

  test('no tariff estimate when price per kWh is not supplied', () {
    final rec = service.build(
      projectName: 'P',
      appliances: [
        Appliance(name: 'A', wattage: 100, quantity: 1, usageHours: 1),
      ],
      inputs: const PlanningInputs(),
    );
    expect(rec.tariffEstimate.configured, false);
    expect(rec.paybackEstimate.configured, false);
  });
}
