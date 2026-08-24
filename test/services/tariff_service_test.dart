import 'package:flutter_test/flutter_test.dart';
import 'package:solar/services/tariff_service.dart';

void main() {
  const service = TariffService();

  test('not configured when price per kWh is missing', () {
    final result = service.computeTariffEstimate(
      monthlyConsumptionKWh: 300,
      monthlySolarOffsetKWh: 200,
    );
    expect(result.configured, false);
  });

  test('computes current cost, offset and potential savings', () {
    final result = service.computeTariffEstimate(
      monthlyConsumptionKWh: 300,
      monthlySolarOffsetKWh: 200,
      pricePerKWh: 0.15,
      fixedChargePerMonth: 10,
    );
    // cost = 300*0.15 + 10 = 55
    expect(result.estimatedCurrentMonthlyCost, closeTo(55, 0.001));
    // offset capped at consumption; here 200 <= 300, so offset = 200
    expect(result.estimatedSolarOffsetKWhPerMonth, closeTo(200, 0.001));
    // savings = 200 * 0.15 = 30
    expect(result.estimatedPotentialMonthlySavings, closeTo(30, 0.001));
  });

  test(
    'solar offset is capped at monthly consumption, never negative-cost',
    () {
      final result = service.computeTariffEstimate(
        monthlyConsumptionKWh: 100,
        monthlySolarOffsetKWh: 500, // way more generation than usage
        pricePerKWh: 0.20,
      );
      expect(result.estimatedSolarOffsetKWhPerMonth, closeTo(100, 0.001));
      expect(result.estimatedPotentialMonthlySavings, closeTo(20, 0.001));
    },
  );

  test('simple payback estimate divides system cost by annual savings', () {
    final tariff = service.computeTariffEstimate(
      monthlyConsumptionKWh: 300,
      monthlySolarOffsetKWh: 300,
      pricePerKWh: 0.25,
    );
    final payback = service.computeSimplePayback(
      systemCost: 3000,
      estimatedPotentialMonthlySavings: tariff.estimatedPotentialMonthlySavings,
    );
    // annual savings = 75 * 12 = 900; payback = 3000/900 = 3.33 yrs
    expect(payback.estimatedPaybackYears, closeTo(3.33, 0.01));
  });

  test('payback is not configured without a system cost', () {
    final payback = service.computeSimplePayback(
      estimatedPotentialMonthlySavings: 50,
    );
    expect(payback.configured, false);
  });

  test('payback is null (not computable) when there are no savings', () {
    final payback = service.computeSimplePayback(
      systemCost: 1000,
      estimatedPotentialMonthlySavings: 0,
    );
    expect(payback.configured, true);
    expect(payback.estimatedPaybackYears, isNull);
  });
}
