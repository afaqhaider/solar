import 'package:flutter_test/flutter_test.dart';
import 'package:solar/models/appliance.dart';
import 'package:solar/models/battery_chemistry.dart';
import 'package:solar/models/planning_inputs.dart';
import 'package:solar/models/system_type.dart';
import 'package:solar/services/system_recommendation_service.dart';

const _service = SystemRecommendationService();

void main() {
  group('Small system — lights, fans, router', () {
    final appliances = [
      Appliance(
        name: 'LED Light',
        wattage: 10,
        quantity: 4,
        usageHours: 6,
        backupRequired: true,
      ),
      Appliance(
        name: 'Fan',
        wattage: 60,
        quantity: 2,
        usageHours: 8,
        backupRequired: true,
      ),
      Appliance(
        name: 'Router',
        wattage: 15,
        quantity: 1,
        usageHours: 24,
        backupRequired: true,
      ),
    ];
    const inputs = PlanningInputs(
      peakSunHours: 5,
      panelWattage: 300,
      backupHours: 4,
      designReservePercent: 0,
    );

    test('load energy is correct', () {
      final rec = _service.build(
        projectName: 'Small',
        appliances: appliances,
        inputs: inputs,
      );
      // (10*4*6) + (60*2*8) + (15*1*24) = 240 + 960 + 360 = 1560 Wh
      expect(rec.loadProfile.dailyEnergyWh, closeTo(1560, 0.001));
    });

    test('solar sizing scales with the small load', () {
      final rec = _service.build(
        projectName: 'Small',
        appliances: appliances,
        inputs: inputs,
      );
      // required = 1560 / 5 / 0.8 = 390 W
      expect(rec.solarArraySizing.requiredArrayW, closeTo(390, 0.001));
      expect(rec.solarArraySizing.panelCount, 2); // ceil(390/300)
    });

    test('battery sizing targets the fully-essential small load', () {
      final rec = _service.build(
        projectName: 'Small',
        appliances: appliances,
        inputs: inputs,
      );
      final runningLoad = 10 * 4 + 60 * 2 + 15; // 175W
      expect(
        rec.essentialLoadProfile.runningLoadW,
        closeTo(runningLoad.toDouble(), 0.001),
      );
      expect(
        rec.batterySizing.requiredUsableWh,
        closeTo(runningLoad * 4, 0.001),
      );
    });

    test('inverter sizing covers the small running load with headroom', () {
      final rec = _service.build(
        projectName: 'Small',
        appliances: appliances,
        inputs: inputs,
      );
      expect(rec.inverterSizing.minInverterW, closeTo(175 / 0.8, 0.01));
    });
  });

  group('Home system — fridge, lighting, fans, TV, computers, A/C', () {
    final appliances = [
      Appliance(
        name: 'Refrigerator',
        wattage: 200,
        quantity: 1,
        usageHours: 24,
        surgeWattage: 600,
        backupRequired: true,
      ),
      Appliance(
        name: 'LED Lighting',
        wattage: 10,
        quantity: 8,
        usageHours: 5,
        backupRequired: true,
      ),
      Appliance(
        name: 'Ceiling Fan',
        wattage: 75,
        quantity: 3,
        usageHours: 8,
        backupRequired: true,
      ),
      Appliance(name: 'Television', wattage: 100, quantity: 1, usageHours: 4),
      Appliance(
        name: 'Desktop Computer',
        wattage: 250,
        quantity: 2,
        usageHours: 6,
      ),
      Appliance(
        name: 'Air Conditioner',
        wattage: 1500,
        quantity: 1,
        usageHours: 6,
        surgeWattage: 2200,
      ),
    ];
    const inputs = PlanningInputs(
      peakSunHours: 5.5,
      panelWattage: 550,
      backupHours: 6,
      batteryChemistry: BatteryChemistry.lifepo4,
      batteryDoD: 90,
      batteryEfficiencyPercent: 97,
      batteryUnitVoltage: 51.2,
      batteryUnitAh: 100,
      designReservePercent: 20,
    );

    test('produces a complete, internally consistent recommendation', () {
      final rec = _service.build(
        projectName: 'Home',
        appliances: appliances,
        inputs: inputs,
      );

      expect(rec.loadProfile.dailyEnergyWh, greaterThan(0));
      expect(
        rec.solarArraySizing.recommendedArrayW,
        greaterThan(rec.solarArraySizing.requiredArrayW),
      );
      expect(rec.batterySizing.backupEnabled, true);
      // Essential load excludes TV, computers and A/C.
      expect(
        rec.essentialLoadProfile.runningLoadW,
        closeTo(200 + 80 + 225, 0.001),
      );
      // Inverter must clear the A/C surge (conservative or standard) plus headroom.
      expect(
        rec.inverterSizing.recommendedInverterW,
        greaterThanOrEqualTo(rec.inverterSizing.minInverterW),
      );
      expect(
        rec.energyBalance.dailyConsumptionWh,
        closeTo(rec.loadProfile.dailyEnergyWh, 0.001),
      );
    });
  });

  group('Off-grid scenario', () {
    final appliances = [
      Appliance(
        name: 'Fridge',
        wattage: 200,
        quantity: 1,
        usageHours: 24,
        backupRequired: true,
      ),
      Appliance(
        name: 'Lighting',
        wattage: 60,
        quantity: 1,
        usageHours: 6,
        backupRequired: true,
      ),
      Appliance(name: 'Water Pump', wattage: 750, quantity: 1, usageHours: 1),
    ];
    const inputs = PlanningInputs(
      systemType: SystemType.offGrid,
      peakSunHours: 4.5,
      panelWattage: 400,
      backupHours: 12,
      designReservePercent: 30,
    );

    test(
      'essential loads, backup duration and storage requirement are consistent',
      () {
        final rec = _service.build(
          projectName: 'Off-Grid',
          appliances: appliances,
          inputs: inputs,
        );
        expect(
          rec.essentialLoadProfile.runningLoadW,
          closeTo(260, 0.001),
        ); // fridge + lighting only
        expect(rec.batterySizing.backupHours, 12);
        expect(
          rec.batterySizing.requiredUsableWh,
          closeTo(260 * 12 * 1.3, 0.001),
        );
      },
    );

    test('energy balance reflects off-grid consumption vs. generation', () {
      final rec = _service.build(
        projectName: 'Off-Grid',
        appliances: appliances,
        inputs: inputs,
      );
      expect(
        rec.energyBalance.dailyGenerationWh,
        closeTo(rec.solarArraySizing.estimatedDailyGenerationWh, 0.001),
      );
    });
  });

  group('Hybrid scenario', () {
    final appliances = [
      Appliance(
        name: 'Fridge',
        wattage: 200,
        quantity: 1,
        usageHours: 24,
        backupRequired: true,
      ),
      Appliance(name: 'Office Load', wattage: 300, quantity: 1, usageHours: 8),
    ];
    const inputs = PlanningInputs(
      systemType: SystemType.hybrid,
      peakSunHours: 5,
      panelWattage: 450,
      backupHours: 4,
    );

    test(
      'sizes solar, battery and reflects a hybrid (grid-backed) system type',
      () {
        final rec = _service.build(
          projectName: 'Hybrid',
          appliances: appliances,
          inputs: inputs,
        );
        expect(rec.assumptions.systemType, SystemType.hybrid);
        expect(rec.assumptions.systemType.batteryRequired, true);
        expect(rec.solarArraySizing.panelCount, greaterThan(0));
        expect(rec.batterySizing.backupEnabled, true);
      },
    );
  });
}
