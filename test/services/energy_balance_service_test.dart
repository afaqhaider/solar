import 'package:flutter_test/flutter_test.dart';
import 'package:solar/services/energy_balance_service.dart';

void main() {
  const service = EnergyBalanceService();

  test('computes surplus when generation exceeds consumption', () {
    final result = service.computeBalance(
      dailyConsumptionWh: 4000,
      dailyGenerationWh: 5000,
    );
    expect(result.surplusWh, closeTo(1000, 0.001));
    expect(result.coveragePercent, closeTo(125, 0.001));
  });

  test('computes shortfall when generation is below consumption', () {
    final result = service.computeBalance(
      dailyConsumptionWh: 5000,
      dailyGenerationWh: 3000,
    );
    expect(result.surplusWh, closeTo(-2000, 0.001));
    expect(result.coveragePercent, closeTo(60, 0.001));
  });

  test('boundary: zero consumption does not throw and coverage is 0', () {
    final result = service.computeBalance(
      dailyConsumptionWh: 0,
      dailyGenerationWh: 1000,
    );
    expect(result.coveragePercent, 0);
    expect(result.surplusWh, 1000);
  });

  test('boundary: zero generation is a full shortfall', () {
    final result = service.computeBalance(
      dailyConsumptionWh: 2000,
      dailyGenerationWh: 0,
    );
    expect(result.coveragePercent, 0);
    expect(result.surplusWh, -2000);
  });
}
