import 'package:flutter_test/flutter_test.dart';
import 'package:solar/models/appliance.dart';

void main() {
  test('dailyWh multiplies wattage, quantity and usage hours', () {
    final a = Appliance(wattage: 100, quantity: 2, usageHours: 3);
    expect(a.dailyWh, 600);
  });

  test('averageDailyWh spreads weekly energy across 7 days', () {
    final a = Appliance(
      wattage: 100,
      quantity: 1,
      usageHours: 1,
      daysPerWeek: 7,
    );
    expect(a.averageDailyWh, 100);

    final occasional = Appliance(
      wattage: 700,
      quantity: 1,
      usageHours: 1,
      daysPerWeek: 1,
    );
    expect(occasional.averageDailyWh, closeTo(100, 0.001));
  });

  test(
    'surgeContributionW is 0 when no surge or surge below running wattage',
    () {
      final noSurge = Appliance(wattage: 100, quantity: 1, usageHours: 1);
      expect(noSurge.surgeContributionW, 0);

      final lowSurge = Appliance(
        wattage: 100,
        quantity: 1,
        usageHours: 1,
        surgeWattage: 90,
      );
      expect(lowSurge.surgeContributionW, 0);
    },
  );

  test(
    'surgeContributionW is the delta above running wattage, times quantity',
    () {
      final a = Appliance(
        wattage: 200,
        quantity: 2,
        usageHours: 1,
        surgeWattage: 600,
      );
      expect(a.surgeContributionW, 800); // (600-200) * 2
    },
  );

  test('round-trips through JSON', () {
    final a = Appliance(
      name: 'Fridge',
      category: 'Kitchen',
      wattage: 200,
      quantity: 1,
      usageHours: 24,
      daysPerWeek: 7,
      surgeWattage: 600,
      enabled: false,
    );
    final restored = Appliance.fromJson(a.toJson());
    expect(restored.name, a.name);
    expect(restored.wattage, a.wattage);
    expect(restored.surgeWattage, a.surgeWattage);
    expect(restored.enabled, a.enabled);
  });
}
