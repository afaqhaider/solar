import '../models/results.dart';

/// Sizes a solar array from a daily energy requirement.
///
/// [requiredArrayW] is the calculated minimum needed to cover the daily
/// energy requirement given peak sun hours and system efficiency.
/// [recommendedArrayW] layers the user's design reserve on top — the two
/// are always reported separately so a "minimum" is never presented as a
/// guarantee.
class SolarSizingService {
  const SolarSizingService();

  SolarArraySizing computeArraySizing({
    required double dailyEnergyWh,
    required double peakSunHours,
    required double systemEfficiencyPercent,
    required double panelWattage,
    double designReservePercent = 0,
  }) {
    if (peakSunHours <= 0 ||
        systemEfficiencyPercent <= 0 ||
        panelWattage <= 0) {
      return SolarArraySizing.empty;
    }

    final efficiencyFactor = systemEfficiencyPercent / 100.0;
    final requiredArrayW = dailyEnergyWh / peakSunHours / efficiencyFactor;
    final recommendedArrayW =
        requiredArrayW * (1 + (designReservePercent / 100.0));

    final panelCount = (recommendedArrayW / panelWattage).ceil();
    final installedCapacityW = panelCount * panelWattage;

    final estimatedDailyGenerationWh =
        installedCapacityW * peakSunHours * efficiencyFactor;
    final estimatedMonthlyGenerationKWh =
        estimatedDailyGenerationWh * 30 / 1000.0;

    return SolarArraySizing(
      requiredArrayW: requiredArrayW,
      recommendedArrayW: recommendedArrayW,
      panelWattage: panelWattage,
      panelCount: panelCount,
      installedCapacityW: installedCapacityW,
      estimatedDailyGenerationWh: estimatedDailyGenerationWh,
      estimatedMonthlyGenerationKWh: estimatedMonthlyGenerationKWh,
    );
  }
}
