import 'appliance.dart';
import 'planning_inputs.dart';
import 'results.dart';

/// The complete, self-contained result of planning a system: everything
/// the System Recommendation screen shows, structured so a future export
/// (PDF/report) can be generated directly from this object without
/// scraping UI widgets.
class SystemRecommendation {
  final String projectName;
  final DateTime generatedAt;

  final List<Appliance> appliances;
  final LoadProfile loadProfile;
  final LoadProfile essentialLoadProfile;

  final SolarArraySizing solarArraySizing;
  final BatteryBankSizing batterySizing;
  final InverterSizing inverterSizing;
  final EnergyBalanceResult energyBalance;
  final TariffEstimate tariffEstimate;
  final PaybackEstimate paybackEstimate;

  final PlanningInputs assumptions;

  /// Name of the scenario this recommendation was generated from, or null
  /// when it represents the live project.
  final String? scenarioName;

  static const disclaimer =
      'This report contains planning estimates only. Actual solar production, battery '
      'runtime and system requirements vary with weather, shading, temperature, equipment '
      'efficiency, battery condition and installation conditions. Select and wire electrical '
      'equipment according to manufacturer specifications, and have final installation and '
      'electrical work verified by an appropriately qualified professional. This is not a '
      'certified engineering calculation.';

  const SystemRecommendation({
    required this.projectName,
    required this.generatedAt,
    required this.appliances,
    required this.loadProfile,
    required this.essentialLoadProfile,
    required this.solarArraySizing,
    required this.batterySizing,
    required this.inverterSizing,
    required this.energyBalance,
    required this.tariffEstimate,
    required this.paybackEstimate,
    required this.assumptions,
    this.scenarioName,
  });
}
