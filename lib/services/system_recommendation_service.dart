import '../models/appliance.dart';
import '../models/planning_inputs.dart';
import '../models/system_recommendation.dart';
import 'battery_sizing_service.dart';
import 'energy_balance_service.dart';
import 'inverter_sizing_service.dart';
import 'load_calculation_service.dart';
import 'solar_sizing_service.dart';
import 'tariff_service.dart';

/// Composes the four sizing services plus energy balance and tariff
/// estimates into one [SystemRecommendation]. This is the single place
/// that turns "appliances + assumptions" into a complete planning result —
/// used by the System screen, What-If exploration, and scenario
/// comparison, so they can never drift out of sync with each other.
class SystemRecommendationService {
  const SystemRecommendationService({
    LoadCalculationService? loadService,
    SolarSizingService? solarService,
    BatterySizingService? batteryService,
    InverterSizingService? inverterService,
    EnergyBalanceService? energyBalanceService,
    TariffService? tariffService,
  }) : _loadService = loadService ?? const LoadCalculationService(),
       _solarService = solarService ?? const SolarSizingService(),
       _batteryService = batteryService ?? const BatterySizingService(),
       _inverterService = inverterService ?? const InverterSizingService(),
       _energyBalanceService =
           energyBalanceService ?? const EnergyBalanceService(),
       _tariffService = tariffService ?? const TariffService();

  final LoadCalculationService _loadService;
  final SolarSizingService _solarService;
  final BatterySizingService _batteryService;
  final InverterSizingService _inverterService;
  final EnergyBalanceService _energyBalanceService;
  final TariffService _tariffService;

  SystemRecommendation build({
    required String projectName,
    required List<Appliance> appliances,
    required PlanningInputs inputs,
    String? scenarioName,
    String currencyLabel = '\$',
    double? pricePerKWh,
    double? fixedChargePerMonth,
    double? estimatedSystemCost,
  }) {
    final loadProfile = _loadService.computeLoadProfile(appliances);
    final essentialLoadProfile = _loadService.computeLoadProfile(
      appliances.where((a) => a.backupRequired).toList(),
    );

    final solarArraySizing = _solarService.computeArraySizing(
      dailyEnergyWh: loadProfile.dailyEnergyWh,
      peakSunHours: inputs.peakSunHours,
      systemEfficiencyPercent: inputs.systemEfficiencyPercent,
      panelWattage: inputs.panelWattage,
      designReservePercent: inputs.designReservePercent,
    );

    final batterySizing = _batteryService.computeBankSizing(
      essentialLoadW: essentialLoadProfile.runningLoadW > 0
          ? essentialLoadProfile.runningLoadW
          : loadProfile.runningLoadW,
      backupHours: inputs.backupHours,
      unitVoltage: inputs.batteryUnitVoltage,
      unitAh: inputs.batteryUnitAh,
      seriesCount: inputs.batterySeriesCount,
      parallelCount: inputs.batteryParallelCount,
      dodPercent: inputs.batteryDoD,
      batteryEfficiencyPercent: inputs.batteryEfficiencyPercent,
      designReservePercent: inputs.designReservePercent,
    );

    final inverterSizing = _inverterService.computeInverterSizing(
      runningLoadW: loadProfile.runningLoadW,
      standardPeakLoadW: loadProfile.standardPeakLoadW,
      conservativePeakLoadW: loadProfile.conservativePeakLoadW,
      surgeMode: inputs.inverterSurgeMode,
      headroomPercent: inputs.inverterHeadroomPercent,
    );

    final energyBalance = _energyBalanceService.computeBalance(
      dailyConsumptionWh: loadProfile.dailyEnergyWh,
      dailyGenerationWh: solarArraySizing.estimatedDailyGenerationWh,
    );

    final tariffEstimate = _tariffService.computeTariffEstimate(
      monthlyConsumptionKWh: loadProfile.monthlyEnergyKWh,
      monthlySolarOffsetKWh: solarArraySizing.estimatedMonthlyGenerationKWh,
      pricePerKWh: pricePerKWh,
      fixedChargePerMonth: fixedChargePerMonth,
      currencyLabel: currencyLabel,
    );

    final paybackEstimate = _tariffService.computeSimplePayback(
      systemCost: estimatedSystemCost,
      estimatedPotentialMonthlySavings:
          tariffEstimate.estimatedPotentialMonthlySavings,
    );

    return SystemRecommendation(
      projectName: projectName,
      generatedAt: DateTime.now(),
      appliances: appliances,
      loadProfile: loadProfile,
      essentialLoadProfile: essentialLoadProfile,
      solarArraySizing: solarArraySizing,
      batterySizing: batterySizing,
      inverterSizing: inverterSizing,
      energyBalance: energyBalance,
      tariffEstimate: tariffEstimate,
      paybackEstimate: paybackEstimate,
      assumptions: inputs,
      scenarioName: scenarioName,
    );
  }
}
