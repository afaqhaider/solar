import '../models/results.dart';

/// Estimates electricity-cost impact and a simple payback period. Always
/// framed as an "estimated potential" figure — never a guaranteed saving,
/// and never investment/financial advice.
class TariffService {
  const TariffService();

  TariffEstimate computeTariffEstimate({
    required double monthlyConsumptionKWh,
    required double monthlySolarOffsetKWh,
    double? pricePerKWh,
    double? fixedChargePerMonth,
    String currencyLabel = '\$',
  }) {
    if (pricePerKWh == null || pricePerKWh <= 0) return TariffEstimate.empty;

    final currentMonthlyCost =
        monthlyConsumptionKWh * pricePerKWh + (fixedChargePerMonth ?? 0);

    // Solar can only offset what's actually consumed.
    final offsetKWh = monthlySolarOffsetKWh > monthlyConsumptionKWh
        ? monthlyConsumptionKWh
        : monthlySolarOffsetKWh;
    final potentialSavings = offsetKWh * pricePerKWh;

    return TariffEstimate(
      configured: true,
      currencyLabel: currencyLabel,
      pricePerKWh: pricePerKWh,
      fixedChargePerMonth: fixedChargePerMonth,
      estimatedCurrentMonthlyCost: currentMonthlyCost,
      estimatedSolarOffsetKWhPerMonth: offsetKWh,
      estimatedPotentialMonthlySavings: potentialSavings,
    );
  }

  PaybackEstimate computeSimplePayback({
    double? systemCost,
    required double estimatedPotentialMonthlySavings,
  }) {
    if (systemCost == null || systemCost <= 0) return PaybackEstimate.empty;

    final annualSavings = estimatedPotentialMonthlySavings * 12;
    return PaybackEstimate(
      configured: true,
      systemCost: systemCost,
      estimatedAnnualSavings: annualSavings,
      estimatedPaybackYears: annualSavings > 0
          ? systemCost / annualSavings
          : null,
    );
  }
}
