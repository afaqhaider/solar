import '../models/results.dart';

/// Compares estimated daily consumption against estimated daily solar
/// generation. A simplified planning comparison, not a forecast.
class EnergyBalanceService {
  const EnergyBalanceService();

  EnergyBalanceResult computeBalance({
    required double dailyConsumptionWh,
    required double dailyGenerationWh,
  }) {
    final surplusWh = dailyGenerationWh - dailyConsumptionWh;
    final coveragePercent = dailyConsumptionWh > 0
        ? (dailyGenerationWh / dailyConsumptionWh) * 100.0
        : 0.0;

    return EnergyBalanceResult(
      dailyConsumptionWh: dailyConsumptionWh,
      dailyGenerationWh: dailyGenerationWh,
      surplusWh: surplusWh,
      coveragePercent: coveragePercent,
    );
  }
}
