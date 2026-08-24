/// Domain result types produced by the calculation services.
/// Kept separate from UI so they stay deterministic and testable.
library;

import 'design_status.dart';

/// One appliance's contribution to the overall load profile, used for the
/// "which appliances consume the most energy" breakdown.
class LoadContribution {
  final String applianceId;
  final String name;
  final double averageDailyWh;
  final double shareOfTotal; // 0.0 - 1.0

  const LoadContribution({
    required this.applianceId,
    required this.name,
    required this.averageDailyWh,
    required this.shareOfTotal,
  });
}

/// Aggregate load profile for a set of appliances.
class LoadProfile {
  final double connectedLoadW;
  final double runningLoadW;

  /// A "typical" peak: running load plus only the single largest surge
  /// delta, on the assumption motor startups are usually staggered.
  final double standardPeakLoadW;

  /// A cautious peak: running load plus every configured surge delta,
  /// assuming relevant startups could overlap.
  final double conservativePeakLoadW;

  final double dailyEnergyWh;
  final double monthlyEnergyKWh;
  final int enabledApplianceCount;
  final int totalApplianceCount;
  final List<LoadContribution> breakdown;

  const LoadProfile({
    this.connectedLoadW = 0,
    this.runningLoadW = 0,
    this.standardPeakLoadW = 0,
    this.conservativePeakLoadW = 0,
    this.dailyEnergyWh = 0,
    this.monthlyEnergyKWh = 0,
    this.enabledApplianceCount = 0,
    this.totalApplianceCount = 0,
    this.breakdown = const [],
  });

  /// Backward/UI-convenience alias for the conservative estimate.
  double get peakLoadW => conservativePeakLoadW;

  static const empty = LoadProfile();
}

/// Solar array sizing outcome. Distinguishes the calculated minimum from
/// the recommended design value (which includes the design reserve).
class SolarArraySizing {
  final double requiredArrayW; // calculated minimum
  final double recommendedArrayW; // includes design reserve
  final double panelWattage;
  final int panelCount;
  final double installedCapacityW;
  final double estimatedDailyGenerationWh;
  final double estimatedMonthlyGenerationKWh;

  const SolarArraySizing({
    this.requiredArrayW = 0,
    this.recommendedArrayW = 0,
    this.panelWattage = 0,
    this.panelCount = 0,
    this.installedCapacityW = 0,
    this.estimatedDailyGenerationWh = 0,
    this.estimatedMonthlyGenerationKWh = 0,
  });

  static const empty = SolarArraySizing();
}

/// Battery bank sizing/evaluation outcome. Used for both Automatic Sizing
/// (given a target backup duration, what bank meets it) and Manual
/// Configuration (given a bank, how does it compare to the requirement).
class BatteryBankSizing {
  final bool backupEnabled;
  final double backupHours;

  // Bank configuration actually being evaluated.
  final double unitVoltage;
  final double unitAh;
  final int seriesCount;
  final int parallelCount;
  final double bankVoltage;
  final double bankAh;
  final double nominalBankWh;
  final double usableBankWh;

  // Requirement, derived from the essential load and target backup.
  final double requiredUsableWh;
  final double requiredNominalWh;
  final int recommendedParallelCount;

  final double surplusUsableWh; // negative = shortfall
  final double estimatedRuntimeHours;
  final DesignStatus status;

  const BatteryBankSizing({
    this.backupEnabled = false,
    this.backupHours = 0,
    this.unitVoltage = 0,
    this.unitAh = 0,
    this.seriesCount = 0,
    this.parallelCount = 0,
    this.bankVoltage = 0,
    this.bankAh = 0,
    this.nominalBankWh = 0,
    this.usableBankWh = 0,
    this.requiredUsableWh = 0,
    this.requiredNominalWh = 0,
    this.recommendedParallelCount = 0,
    this.surplusUsableWh = 0,
    this.estimatedRuntimeHours = 0,
    this.status = DesignStatus.configurationIncomplete,
  });

  static const empty = BatteryBankSizing();
}

/// Inverter sizing outcome, showing the inputs that produced it so the
/// user can see why the recommendation was generated.
class InverterSizing {
  final double runningLoadW;
  final double surgeLoadW;
  final double headroomPercent;
  final double minInverterW;
  final double recommendedInverterW;

  const InverterSizing({
    this.runningLoadW = 0,
    this.surgeLoadW = 0,
    this.headroomPercent = 0,
    this.minInverterW = 0,
    this.recommendedInverterW = 0,
  });

  static const empty = InverterSizing();
}

/// Estimated daily energy consumption vs. estimated daily solar generation.
class EnergyBalanceResult {
  final double dailyConsumptionWh;
  final double dailyGenerationWh;
  final double surplusWh; // negative = shortfall
  final double coveragePercent; // generation as % of consumption

  const EnergyBalanceResult({
    this.dailyConsumptionWh = 0,
    this.dailyGenerationWh = 0,
    this.surplusWh = 0,
    this.coveragePercent = 0,
  });

  static const empty = EnergyBalanceResult();
}

/// Estimated electricity-cost impact. Framed as an estimate throughout —
/// never a guaranteed savings figure.
class TariffEstimate {
  final bool configured;
  final String currencyLabel;
  final double pricePerKWh;
  final double? fixedChargePerMonth;
  final double estimatedCurrentMonthlyCost;
  final double estimatedSolarOffsetKWhPerMonth;
  final double estimatedPotentialMonthlySavings;

  const TariffEstimate({
    this.configured = false,
    this.currencyLabel = '\$',
    this.pricePerKWh = 0,
    this.fixedChargePerMonth,
    this.estimatedCurrentMonthlyCost = 0,
    this.estimatedSolarOffsetKWhPerMonth = 0,
    this.estimatedPotentialMonthlySavings = 0,
  });

  static const empty = TariffEstimate();
}

/// A simple, non-financial-advice payback estimate.
class PaybackEstimate {
  final bool configured;
  final double systemCost;
  final double estimatedAnnualSavings;
  final double? estimatedPaybackYears; // null if savings <= 0

  const PaybackEstimate({
    this.configured = false,
    this.systemCost = 0,
    this.estimatedAnnualSavings = 0,
    this.estimatedPaybackYears,
  });

  static const empty = PaybackEstimate();
}
