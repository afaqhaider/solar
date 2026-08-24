import 'battery_chemistry.dart';
import 'battery_sizing_mode.dart';
import 'surge_mode.dart';
import 'system_type.dart';

/// The full set of user-adjustable planning assumptions used to size a
/// system from a load profile. Extracted from [SolarProject] so the same
/// bundle can drive the live project, a What-If exploration, or a saved
/// [ProjectScenario] through the same calculation services.
class PlanningInputs {
  final SystemType systemType;

  // Solar
  final double peakSunHours;
  final double systemEfficiencyPercent;
  final double designReservePercent;
  final double panelWattage;

  // Battery
  final BatterySizingMode batterySizingMode;
  final double backupHours;
  final BatteryChemistry batteryChemistry;
  final double batteryUnitVoltage;
  final double batteryUnitAh;
  final int batterySeriesCount;
  final int batteryParallelCount;
  final double batteryDoD;
  final double batteryEfficiencyPercent;

  // Inverter
  final double inverterHeadroomPercent;
  final SurgeMode inverterSurgeMode;

  const PlanningInputs({
    this.systemType = SystemType.hybrid,
    this.peakSunHours = 5,
    this.systemEfficiencyPercent = 80,
    this.designReservePercent = 20,
    this.panelWattage = 550,
    this.batterySizingMode = BatterySizingMode.automatic,
    this.backupHours = 0,
    this.batteryChemistry = BatteryChemistry.leadAcid,
    this.batteryUnitVoltage = 12,
    this.batteryUnitAh = 100,
    this.batterySeriesCount = 1,
    this.batteryParallelCount = 1,
    this.batteryDoD = 50,
    this.batteryEfficiencyPercent = 85,
    this.inverterHeadroomPercent = 20,
    this.inverterSurgeMode = SurgeMode.standard,
  });

  PlanningInputs copyWith({
    SystemType? systemType,
    double? peakSunHours,
    double? systemEfficiencyPercent,
    double? designReservePercent,
    double? panelWattage,
    BatterySizingMode? batterySizingMode,
    double? backupHours,
    BatteryChemistry? batteryChemistry,
    double? batteryUnitVoltage,
    double? batteryUnitAh,
    int? batterySeriesCount,
    int? batteryParallelCount,
    double? batteryDoD,
    double? batteryEfficiencyPercent,
    double? inverterHeadroomPercent,
    SurgeMode? inverterSurgeMode,
  }) {
    return PlanningInputs(
      systemType: systemType ?? this.systemType,
      peakSunHours: peakSunHours ?? this.peakSunHours,
      systemEfficiencyPercent:
          systemEfficiencyPercent ?? this.systemEfficiencyPercent,
      designReservePercent: designReservePercent ?? this.designReservePercent,
      panelWattage: panelWattage ?? this.panelWattage,
      batterySizingMode: batterySizingMode ?? this.batterySizingMode,
      backupHours: backupHours ?? this.backupHours,
      batteryChemistry: batteryChemistry ?? this.batteryChemistry,
      batteryUnitVoltage: batteryUnitVoltage ?? this.batteryUnitVoltage,
      batteryUnitAh: batteryUnitAh ?? this.batteryUnitAh,
      batterySeriesCount: batterySeriesCount ?? this.batterySeriesCount,
      batteryParallelCount: batteryParallelCount ?? this.batteryParallelCount,
      batteryDoD: batteryDoD ?? this.batteryDoD,
      batteryEfficiencyPercent:
          batteryEfficiencyPercent ?? this.batteryEfficiencyPercent,
      inverterHeadroomPercent:
          inverterHeadroomPercent ?? this.inverterHeadroomPercent,
      inverterSurgeMode: inverterSurgeMode ?? this.inverterSurgeMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'systemType': systemType.name,
    'peakSunHours': peakSunHours,
    'systemEfficiencyPercent': systemEfficiencyPercent,
    'designReservePercent': designReservePercent,
    'panelWattage': panelWattage,
    'batterySizingMode': batterySizingMode.name,
    'backupHours': backupHours,
    'batteryChemistry': batteryChemistry.name,
    'batteryUnitVoltage': batteryUnitVoltage,
    'batteryUnitAh': batteryUnitAh,
    'batterySeriesCount': batterySeriesCount,
    'batteryParallelCount': batteryParallelCount,
    'batteryDoD': batteryDoD,
    'batteryEfficiencyPercent': batteryEfficiencyPercent,
    'inverterHeadroomPercent': inverterHeadroomPercent,
    'inverterSurgeMode': inverterSurgeMode.name,
  };

  factory PlanningInputs.fromJson(Map<String, dynamic> json) => PlanningInputs(
    systemType: SystemType.fromName(json['systemType'] as String?),
    peakSunHours: (json['peakSunHours'] as num?)?.toDouble() ?? 5,
    systemEfficiencyPercent:
        (json['systemEfficiencyPercent'] as num?)?.toDouble() ?? 80,
    designReservePercent:
        (json['designReservePercent'] as num?)?.toDouble() ?? 20,
    panelWattage: (json['panelWattage'] as num?)?.toDouble() ?? 550,
    batterySizingMode: BatterySizingMode.fromName(
      json['batterySizingMode'] as String?,
    ),
    backupHours: (json['backupHours'] as num?)?.toDouble() ?? 0,
    batteryChemistry: BatteryChemistry.fromName(
      json['batteryChemistry'] as String?,
    ),
    batteryUnitVoltage: (json['batteryUnitVoltage'] as num?)?.toDouble() ?? 12,
    batteryUnitAh: (json['batteryUnitAh'] as num?)?.toDouble() ?? 100,
    batterySeriesCount: (json['batterySeriesCount'] as num?)?.toInt() ?? 1,
    batteryParallelCount: (json['batteryParallelCount'] as num?)?.toInt() ?? 1,
    batteryDoD: (json['batteryDoD'] as num?)?.toDouble() ?? 50,
    batteryEfficiencyPercent:
        (json['batteryEfficiencyPercent'] as num?)?.toDouble() ?? 85,
    inverterHeadroomPercent:
        (json['inverterHeadroomPercent'] as num?)?.toDouble() ?? 20,
    inverterSurgeMode: SurgeMode.fromName(json['inverterSurgeMode'] as String?),
  );
}
