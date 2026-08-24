import 'package:flutter_test/flutter_test.dart';
import 'package:solar/models/appliance.dart';
import 'package:solar/services/load_calculation_service.dart';

void main() {
  const service = LoadCalculationService();

  test('empty appliance list returns an empty profile', () {
    final profile = service.computeLoadProfile([]);
    expect(profile.connectedLoadW, 0);
    expect(profile.dailyEnergyWh, 0);
    expect(profile.breakdown, isEmpty);
  });

  test('computes connected load and daily energy for daily-use appliances', () {
    final appliances = [
      Appliance(name: 'LED Light', wattage: 12, quantity: 4, usageHours: 6),
      Appliance(name: 'Fridge', wattage: 200, quantity: 1, usageHours: 24),
    ];
    final profile = service.computeLoadProfile(appliances);

    // Connected load: 12*4 + 200*1 = 248 W
    expect(profile.connectedLoadW, 248);
    // Daily energy: (12*4*6) + (200*1*24) = 288 + 4800 = 5088 Wh
    expect(profile.dailyEnergyWh, 5088);
    expect(profile.enabledApplianceCount, 2);
  });

  test('disabled appliances are excluded from all totals', () {
    final appliances = [
      Appliance(
        name: 'A',
        wattage: 100,
        quantity: 1,
        usageHours: 5,
        enabled: true,
      ),
      Appliance(
        name: 'B',
        wattage: 500,
        quantity: 1,
        usageHours: 5,
        enabled: false,
      ),
    ];
    final profile = service.computeLoadProfile(appliances);
    expect(profile.connectedLoadW, 100);
    expect(profile.totalApplianceCount, 2);
    expect(profile.enabledApplianceCount, 1);
  });

  test('daysPerWeek averages energy across the full week', () {
    final appliances = [
      Appliance(
        name: 'Washer',
        wattage: 500,
        quantity: 1,
        usageHours: 1,
        daysPerWeek: 7,
      ),
      Appliance(
        name: 'Occasional',
        wattage: 1400,
        quantity: 1,
        usageHours: 1,
        daysPerWeek: 1,
      ),
    ];
    final profile = service.computeLoadProfile(appliances);
    // Washer: 500Wh/day used daily -> averageDailyWh 500
    // Occasional: 1400Wh on the one day used per week -> averageDailyWh 1400/7 = 200
    expect(profile.dailyEnergyWh, closeTo(700, 0.001));
  });

  test('surge wattage only affects peak load, not daily energy', () {
    final appliances = [
      Appliance(
        name: 'Fridge',
        wattage: 200,
        quantity: 1,
        usageHours: 24,
        surgeWattage: 600,
      ),
    ];
    final profile = service.computeLoadProfile(appliances);
    expect(profile.connectedLoadW, 200);
    expect(profile.peakLoadW, 600); // 200 running + (600-200) surge delta
    expect(profile.dailyEnergyWh, 4800);
  });

  test(
    'standard peak assumes only the single largest surge starts at once',
    () {
      final appliances = [
        Appliance(
          name: 'Fridge',
          wattage: 200,
          quantity: 1,
          usageHours: 24,
          surgeWattage: 600,
        ), // +400
        Appliance(
          name: 'Pump',
          wattage: 300,
          quantity: 1,
          usageHours: 1,
          surgeWattage: 900,
        ), // +600
      ];
      final profile = service.computeLoadProfile(appliances);
      // running = 500; standard peak = 500 + max(400,600) = 1100
      expect(profile.standardPeakLoadW, closeTo(1100, 0.001));
      // conservative peak = 500 + 400 + 600 = 1500
      expect(profile.conservativePeakLoadW, closeTo(1500, 0.001));
    },
  );

  test(
    'backupRequired appliances can be filtered by the caller for essential load',
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
          usageHours: 6,
          backupRequired: false,
        ),
      ];
      final essentialOnly = appliances.where((a) => a.backupRequired).toList();
      final profile = service.computeLoadProfile(essentialOnly);
      expect(profile.connectedLoadW, 200);
      expect(profile.enabledApplianceCount, 1);
    },
  );

  test('breakdown is sorted by contribution, descending', () {
    final appliances = [
      Appliance(name: 'Small', wattage: 10, quantity: 1, usageHours: 1),
      Appliance(name: 'Big', wattage: 1000, quantity: 1, usageHours: 1),
    ];
    final profile = service.computeLoadProfile(appliances);
    expect(profile.breakdown.first.name, 'Big');
    expect(
      profile.breakdown.first.shareOfTotal,
      greaterThan(profile.breakdown.last.shareOfTotal),
    );
  });
}
