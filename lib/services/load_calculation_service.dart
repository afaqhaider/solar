import '../models/appliance.dart';
import '../models/results.dart';

/// Computes connected/running/peak load and daily & monthly energy
/// consumption for a set of appliances. Disabled appliances are excluded.
///
/// Used both for the full appliance list and, filtered by the caller, for
/// the Essential Load Profile (appliances marked "backup required").
class LoadCalculationService {
  const LoadCalculationService();

  LoadProfile computeLoadProfile(List<Appliance> appliances) {
    final active = appliances.where((a) => a.enabled).toList();
    if (active.isEmpty) {
      return LoadProfile(totalApplianceCount: appliances.length);
    }

    final connectedLoadW = active.fold<double>(
      0,
      (sum, a) => sum + a.connectedLoadContributionW,
    );

    final surgeDeltas = active.map((a) => a.surgeContributionW).toList();
    final largestSurgeDelta = surgeDeltas.isEmpty
        ? 0.0
        : surgeDeltas.reduce((a, b) => a > b ? a : b);
    final totalSurgeDelta = surgeDeltas.fold<double>(0, (sum, d) => sum + d);

    // Standard: assume only the single largest motor starts at once.
    final standardPeakLoadW = connectedLoadW + largestSurgeDelta;
    // Conservative: assume every configured surge could overlap.
    final conservativePeakLoadW = connectedLoadW + totalSurgeDelta;

    final dailyEnergyWh = active.fold<double>(
      0,
      (sum, a) => sum + a.averageDailyWh,
    );
    final monthlyEnergyKWh = active.fold<double>(
      0,
      (sum, a) => sum + a.averageMonthlyKWh,
    );

    final breakdown =
        active
            .map(
              (a) => LoadContribution(
                applianceId: a.id,
                name: a.name,
                averageDailyWh: a.averageDailyWh,
                shareOfTotal: dailyEnergyWh > 0
                    ? a.averageDailyWh / dailyEnergyWh
                    : 0.0,
              ),
            )
            .toList()
          ..sort((x, y) => y.averageDailyWh.compareTo(x.averageDailyWh));

    return LoadProfile(
      connectedLoadW: connectedLoadW,
      runningLoadW: connectedLoadW,
      standardPeakLoadW: standardPeakLoadW,
      conservativePeakLoadW: conservativePeakLoadW,
      dailyEnergyWh: dailyEnergyWh,
      monthlyEnergyKWh: monthlyEnergyKWh,
      enabledApplianceCount: active.length,
      totalApplianceCount: appliances.length,
      breakdown: breakdown,
    );
  }
}
