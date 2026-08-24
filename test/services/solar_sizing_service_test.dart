import 'package:flutter_test/flutter_test.dart';
import 'package:solar/services/solar_sizing_service.dart';

void main() {
  const service = SolarSizingService();

  test('returns empty result for invalid inputs', () {
    final result = service.computeArraySizing(
      dailyEnergyWh: 5000,
      peakSunHours: 0,
      systemEfficiencyPercent: 80,
      panelWattage: 550,
    );
    expect(result.panelCount, 0);
    expect(result.requiredArrayW, 0);
  });

  test(
    'computes required and recommended array wattage with a design reserve',
    () {
      final result = service.computeArraySizing(
        dailyEnergyWh: 4000,
        peakSunHours: 5,
        systemEfficiencyPercent: 80,
        panelWattage: 400,
        designReservePercent: 20,
      );
      // required = 4000 / 5 / 0.8 = 1000 W
      expect(result.requiredArrayW, closeTo(1000, 0.001));
      // recommended = 1000 * 1.2 = 1200 W
      expect(result.recommendedArrayW, closeTo(1200, 0.001));
      // panelCount = ceil(1200 / 400) = 3
      expect(result.panelCount, 3);
      expect(result.installedCapacityW, 1200);
    },
  );

  test('panel count always rounds up to cover the recommended wattage', () {
    final result = service.computeArraySizing(
      dailyEnergyWh: 3000,
      peakSunHours: 5,
      systemEfficiencyPercent: 100,
      panelWattage: 550,
    );
    // required = recommended = 600 W -> ceil(600/550) = 2 panels
    expect(result.panelCount, 2);
    expect(result.installedCapacityW, 1100);
  });

  test(
    'estimated generation reflects installed capacity, not just the requirement',
    () {
      final result = service.computeArraySizing(
        dailyEnergyWh: 4000,
        peakSunHours: 5,
        systemEfficiencyPercent: 80,
        panelWattage: 400,
        designReservePercent: 20,
      );
      // installed capacity 1200W * 5h * 0.8 = 4800 Wh
      expect(result.estimatedDailyGenerationWh, closeTo(4800, 0.001));
      expect(
        result.estimatedMonthlyGenerationKWh,
        closeTo(4800 * 30 / 1000, 0.001),
      );
    },
  );

  test(
    'boundary: a very small system (single LED) still sizes without error',
    () {
      final result = service.computeArraySizing(
        dailyEnergyWh: 12, // one 12W LED for 1 hour
        peakSunHours: 5,
        systemEfficiencyPercent: 80,
        panelWattage: 100,
      );
      expect(result.panelCount, 1);
      expect(result.requiredArrayW, greaterThan(0));
    },
  );

  test(
    'boundary: a very large system scales without overflow or precision loss',
    () {
      final result = service.computeArraySizing(
        dailyEnergyWh: 500000000, // 500 MWh/day — an intentionally huge load
        peakSunHours: 5,
        systemEfficiencyPercent: 80,
        panelWattage: 550,
        designReservePercent: 20,
      );
      expect(result.panelCount, greaterThan(0));
      expect(result.recommendedArrayW.isFinite, true);
      expect(result.recommendedArrayW, greaterThan(result.requiredArrayW));
    },
  );

  test(
    'boundary: zero panel wattage returns an empty result rather than dividing by zero',
    () {
      final result = service.computeArraySizing(
        dailyEnergyWh: 4000,
        peakSunHours: 5,
        systemEfficiencyPercent: 80,
        panelWattage: 0,
      );
      expect(result.panelCount, 0);
    },
  );
}
