import 'package:uuid/uuid.dart';
import 'activity_entry.dart';
import 'appliance.dart';
import 'battery_chemistry.dart';
import 'battery_sizing_mode.dart';
import 'equipment_specs.dart';
import 'planning_inputs.dart';
import 'project_status.dart';
import 'scenario.dart';
import 'surge_mode.dart';
import 'system_type.dart';

/// Cap on stored activity entries so the timeline never grows unbounded.
const int _maxActivityEntries = 60;

/// A saved solar planning project: a load profile plus the solar, battery,
/// inverter and equipment assumptions used to size a system for it, along
/// with light workspace metadata (description, notes, activity history).
class SolarProject {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Workspace metadata (all optional except name/timestamps)
  final String description;
  final String projectType; // free-form, e.g. "Residential", "Commercial"
  final String siteLabel;
  final String clientReference;
  final String installationNotes;
  final String notes;
  final bool manuallyReviewed;

  final List<Appliance> appliances;

  final SystemType systemType;

  // Solar / site assumptions
  final double peakSunHours;
  final double
  systemEfficiencyPercent; // accounts for wiring/inverter/soiling losses
  final double
  designReservePercent; // extra margin added on top of the calculated minimum
  final double panelWattage;
  final double? panelVoltage;
  final double? panelCurrentAmps;

  // Battery / backup assumptions
  final BatterySizingMode batterySizingMode;
  final double backupHours;
  final BatteryChemistry batteryChemistry;
  final double batteryVoltage; // per-unit voltage
  final double batteryAh; // per-unit capacity
  final int batterySeriesCount;
  final int batteryParallelCount;
  final double batteryDoD;
  final double batteryEfficiencyPercent;

  // Inverter assumptions
  final double inverterHeadroomPercent;
  final SurgeMode inverterSurgeMode;

  // Tariff / cost assumptions (optional)
  final String currencyLabel;
  final double? pricePerKWh;
  final double? fixedChargePerMonth;
  final double? estimatedSystemCost;

  // Equipment Workspace (all optional)
  final PanelSpec? selectedPanel;
  final BatteryEquipmentSpec? selectedBattery;
  final InverterSpec? selectedInverter;
  final int stringPanelsPerString;
  final int stringParallelStrings;

  final List<ProjectScenario> scenarios;
  final List<ActivityEntry> activity;

  const SolarProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.projectType = '',
    this.siteLabel = '',
    this.clientReference = '',
    this.installationNotes = '',
    this.notes = '',
    this.manuallyReviewed = false,
    this.appliances = const [],
    this.systemType = SystemType.hybrid,
    this.peakSunHours = 5,
    this.systemEfficiencyPercent = 80,
    this.designReservePercent = 20,
    this.panelWattage = 550,
    this.panelVoltage,
    this.panelCurrentAmps,
    this.batterySizingMode = BatterySizingMode.automatic,
    this.backupHours = 0,
    this.batteryChemistry = BatteryChemistry.leadAcid,
    this.batteryVoltage = 12,
    this.batteryAh = 100,
    this.batterySeriesCount = 1,
    this.batteryParallelCount = 1,
    this.batteryDoD = 50,
    this.batteryEfficiencyPercent = 85,
    this.inverterHeadroomPercent = 20,
    this.inverterSurgeMode = SurgeMode.standard,
    this.currencyLabel = '\$',
    this.pricePerKWh,
    this.fixedChargePerMonth,
    this.estimatedSystemCost,
    this.selectedPanel,
    this.selectedBattery,
    this.selectedInverter,
    this.stringPanelsPerString = 1,
    this.stringParallelStrings = 1,
    this.scenarios = const [],
    this.activity = const [],
  });

  factory SolarProject.create(
    String name, {
    double? defaultSystemEfficiencyPercent,
    double? defaultDesignReservePercent,
    double? defaultInverterHeadroomPercent,
    String? defaultCurrencyLabel,
  }) {
    final now = DateTime.now();
    return SolarProject(
      id: const Uuid().v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
      systemEfficiencyPercent: defaultSystemEfficiencyPercent ?? 80,
      designReservePercent: defaultDesignReservePercent ?? 20,
      inverterHeadroomPercent: defaultInverterHeadroomPercent ?? 20,
      currencyLabel: defaultCurrencyLabel ?? '\$',
      activity: [ActivityEntry(timestamp: now, message: 'Project created')],
    );
  }

  /// Workflow state. "Reviewed" only reflects the user's own manual choice
  /// — the app never certifies or approves a plan.
  ProjectStatus get status {
    if (manuallyReviewed) return ProjectStatus.reviewed;
    final hasLoads = appliances.any((a) => a.enabled);
    final hasSolarConfigured = peakSunHours > 0 && panelWattage > 0;
    final batteryOk = !systemType.batteryRequired || backupHours > 0;
    return (hasLoads && hasSolarConfigured && batteryOk)
        ? ProjectStatus.readyForReview
        : ProjectStatus.draft;
  }

  /// The subset of solar/battery/inverter assumptions used by the
  /// calculation services, bundled so the same inputs can drive the live
  /// project, a What-If exploration, or a saved scenario.
  PlanningInputs toPlanningInputs() => PlanningInputs(
    systemType: systemType,
    peakSunHours: peakSunHours,
    systemEfficiencyPercent: systemEfficiencyPercent,
    designReservePercent: designReservePercent,
    panelWattage: panelWattage,
    batterySizingMode: batterySizingMode,
    backupHours: backupHours,
    batteryChemistry: batteryChemistry,
    batteryUnitVoltage: batteryVoltage,
    batteryUnitAh: batteryAh,
    batterySeriesCount: batterySeriesCount,
    batteryParallelCount: batteryParallelCount,
    batteryDoD: batteryDoD,
    batteryEfficiencyPercent: batteryEfficiencyPercent,
    inverterHeadroomPercent: inverterHeadroomPercent,
    inverterSurgeMode: inverterSurgeMode,
  );

  /// Appends an activity entry, trimming to the most recent
  /// [_maxActivityEntries] so the timeline never grows unbounded.
  List<ActivityEntry> _withActivity(String message) {
    final next = [...activity, ActivityEntry(message: message)];
    if (next.length <= _maxActivityEntries) return next;
    return next.sublist(next.length - _maxActivityEntries);
  }

  SolarProject copyWith({
    String? name,
    DateTime? updatedAt,
    String? description,
    String? projectType,
    String? siteLabel,
    String? clientReference,
    String? installationNotes,
    String? notes,
    bool? manuallyReviewed,
    List<Appliance>? appliances,
    SystemType? systemType,
    double? peakSunHours,
    double? systemEfficiencyPercent,
    double? designReservePercent,
    double? panelWattage,
    double? panelVoltage,
    bool clearPanelVoltage = false,
    double? panelCurrentAmps,
    bool clearPanelCurrent = false,
    BatterySizingMode? batterySizingMode,
    double? backupHours,
    BatteryChemistry? batteryChemistry,
    double? batteryVoltage,
    double? batteryAh,
    int? batterySeriesCount,
    int? batteryParallelCount,
    double? batteryDoD,
    double? batteryEfficiencyPercent,
    double? inverterHeadroomPercent,
    SurgeMode? inverterSurgeMode,
    String? currencyLabel,
    double? pricePerKWh,
    bool clearPricePerKWh = false,
    double? fixedChargePerMonth,
    bool clearFixedCharge = false,
    double? estimatedSystemCost,
    bool clearSystemCost = false,
    PanelSpec? selectedPanel,
    bool clearSelectedPanel = false,
    BatteryEquipmentSpec? selectedBattery,
    bool clearSelectedBattery = false,
    InverterSpec? selectedInverter,
    bool clearSelectedInverter = false,
    int? stringPanelsPerString,
    int? stringParallelStrings,
    List<ProjectScenario>? scenarios,
    List<ActivityEntry>? activity,
    String? logActivity,
  }) {
    return SolarProject(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      description: description ?? this.description,
      projectType: projectType ?? this.projectType,
      siteLabel: siteLabel ?? this.siteLabel,
      clientReference: clientReference ?? this.clientReference,
      installationNotes: installationNotes ?? this.installationNotes,
      notes: notes ?? this.notes,
      manuallyReviewed: manuallyReviewed ?? this.manuallyReviewed,
      appliances: appliances ?? this.appliances,
      systemType: systemType ?? this.systemType,
      peakSunHours: peakSunHours ?? this.peakSunHours,
      systemEfficiencyPercent:
          systemEfficiencyPercent ?? this.systemEfficiencyPercent,
      designReservePercent: designReservePercent ?? this.designReservePercent,
      panelWattage: panelWattage ?? this.panelWattage,
      panelVoltage: clearPanelVoltage
          ? null
          : (panelVoltage ?? this.panelVoltage),
      panelCurrentAmps: clearPanelCurrent
          ? null
          : (panelCurrentAmps ?? this.panelCurrentAmps),
      batterySizingMode: batterySizingMode ?? this.batterySizingMode,
      backupHours: backupHours ?? this.backupHours,
      batteryChemistry: batteryChemistry ?? this.batteryChemistry,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      batteryAh: batteryAh ?? this.batteryAh,
      batterySeriesCount: batterySeriesCount ?? this.batterySeriesCount,
      batteryParallelCount: batteryParallelCount ?? this.batteryParallelCount,
      batteryDoD: batteryDoD ?? this.batteryDoD,
      batteryEfficiencyPercent:
          batteryEfficiencyPercent ?? this.batteryEfficiencyPercent,
      inverterHeadroomPercent:
          inverterHeadroomPercent ?? this.inverterHeadroomPercent,
      inverterSurgeMode: inverterSurgeMode ?? this.inverterSurgeMode,
      currencyLabel: currencyLabel ?? this.currencyLabel,
      pricePerKWh: clearPricePerKWh ? null : (pricePerKWh ?? this.pricePerKWh),
      fixedChargePerMonth: clearFixedCharge
          ? null
          : (fixedChargePerMonth ?? this.fixedChargePerMonth),
      estimatedSystemCost: clearSystemCost
          ? null
          : (estimatedSystemCost ?? this.estimatedSystemCost),
      selectedPanel: clearSelectedPanel
          ? null
          : (selectedPanel ?? this.selectedPanel),
      selectedBattery: clearSelectedBattery
          ? null
          : (selectedBattery ?? this.selectedBattery),
      selectedInverter: clearSelectedInverter
          ? null
          : (selectedInverter ?? this.selectedInverter),
      stringPanelsPerString:
          stringPanelsPerString ?? this.stringPanelsPerString,
      stringParallelStrings:
          stringParallelStrings ?? this.stringParallelStrings,
      scenarios: scenarios ?? this.scenarios,
      activity:
          activity ??
          (logActivity != null ? _withActivity(logActivity) : this.activity),
    );
  }

  SolarProject duplicated() {
    final now = DateTime.now();
    return SolarProject(
      id: const Uuid().v4(),
      name: '$name (copy)',
      createdAt: now,
      updatedAt: now,
      description: description,
      projectType: projectType,
      siteLabel: siteLabel,
      clientReference: clientReference,
      installationNotes: installationNotes,
      notes: notes,
      manuallyReviewed: false,
      appliances: appliances.map((a) => a.duplicated()).toList(),
      systemType: systemType,
      peakSunHours: peakSunHours,
      systemEfficiencyPercent: systemEfficiencyPercent,
      designReservePercent: designReservePercent,
      panelWattage: panelWattage,
      panelVoltage: panelVoltage,
      panelCurrentAmps: panelCurrentAmps,
      batterySizingMode: batterySizingMode,
      backupHours: backupHours,
      batteryChemistry: batteryChemistry,
      batteryVoltage: batteryVoltage,
      batteryAh: batteryAh,
      batterySeriesCount: batterySeriesCount,
      batteryParallelCount: batteryParallelCount,
      batteryDoD: batteryDoD,
      batteryEfficiencyPercent: batteryEfficiencyPercent,
      inverterHeadroomPercent: inverterHeadroomPercent,
      inverterSurgeMode: inverterSurgeMode,
      currencyLabel: currencyLabel,
      pricePerKWh: pricePerKWh,
      fixedChargePerMonth: fixedChargePerMonth,
      estimatedSystemCost: estimatedSystemCost,
      selectedPanel: selectedPanel,
      selectedBattery: selectedBattery,
      selectedInverter: selectedInverter,
      stringPanelsPerString: stringPanelsPerString,
      stringParallelStrings: stringParallelStrings,
      // Scenarios are copied by value (new list instance); activity restarts
      // fresh for the copy rather than inheriting the original's history.
      scenarios: scenarios.map((s) => s).toList(),
      activity: [
        ActivityEntry(
          timestamp: now,
          message: 'Project duplicated from "$name"',
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'description': description,
    'projectType': projectType,
    'siteLabel': siteLabel,
    'clientReference': clientReference,
    'installationNotes': installationNotes,
    'notes': notes,
    'manuallyReviewed': manuallyReviewed,
    'appliances': appliances.map((a) => a.toJson()).toList(),
    'systemType': systemType.name,
    'peakSunHours': peakSunHours,
    'systemEfficiencyPercent': systemEfficiencyPercent,
    'designReservePercent': designReservePercent,
    'panelWattage': panelWattage,
    'panelVoltage': panelVoltage,
    'panelCurrentAmps': panelCurrentAmps,
    'batterySizingMode': batterySizingMode.name,
    'backupHours': backupHours,
    'batteryChemistry': batteryChemistry.name,
    'batteryVoltage': batteryVoltage,
    'batteryAh': batteryAh,
    'batterySeriesCount': batterySeriesCount,
    'batteryParallelCount': batteryParallelCount,
    'batteryDoD': batteryDoD,
    'batteryEfficiencyPercent': batteryEfficiencyPercent,
    'inverterHeadroomPercent': inverterHeadroomPercent,
    'inverterSurgeMode': inverterSurgeMode.name,
    'currencyLabel': currencyLabel,
    'pricePerKWh': pricePerKWh,
    'fixedChargePerMonth': fixedChargePerMonth,
    'estimatedSystemCost': estimatedSystemCost,
    'selectedPanel': selectedPanel?.toJson(),
    'selectedBattery': selectedBattery?.toJson(),
    'selectedInverter': selectedInverter?.toJson(),
    'stringPanelsPerString': stringPanelsPerString,
    'stringParallelStrings': stringParallelStrings,
    'scenarios': scenarios.map((s) => s.toJson()).toList(),
    'activity': activity.map((a) => a.toJson()).toList(),
  };

  /// Builds a project from persisted JSON. Every Phase 2/3 field is read
  /// with a safe default so projects saved by earlier app versions (which
  /// predate these keys) load without any destructive migration step.
  factory SolarProject.fromJson(Map<String, dynamic> json) => SolarProject(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Untitled Project',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    description: json['description'] as String? ?? '',
    projectType: json['projectType'] as String? ?? '',
    siteLabel: json['siteLabel'] as String? ?? '',
    clientReference: json['clientReference'] as String? ?? '',
    installationNotes: json['installationNotes'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    manuallyReviewed: json['manuallyReviewed'] as bool? ?? false,
    appliances: (json['appliances'] as List<dynamic>? ?? [])
        .map((e) => Appliance.fromJson(e as Map<String, dynamic>))
        .toList(),
    systemType: SystemType.fromName(json['systemType'] as String?),
    peakSunHours: (json['peakSunHours'] as num?)?.toDouble() ?? 5,
    systemEfficiencyPercent:
        (json['systemEfficiencyPercent'] as num?)?.toDouble() ?? 80,
    designReservePercent:
        (json['designReservePercent'] as num?)?.toDouble() ?? 20,
    panelWattage: (json['panelWattage'] as num?)?.toDouble() ?? 550,
    panelVoltage: (json['panelVoltage'] as num?)?.toDouble(),
    panelCurrentAmps: (json['panelCurrentAmps'] as num?)?.toDouble(),
    batterySizingMode: BatterySizingMode.fromName(
      json['batterySizingMode'] as String?,
    ),
    backupHours: (json['backupHours'] as num?)?.toDouble() ?? 0,
    batteryChemistry: BatteryChemistry.fromName(
      json['batteryChemistry'] as String?,
    ),
    batteryVoltage: (json['batteryVoltage'] as num?)?.toDouble() ?? 12,
    batteryAh: (json['batteryAh'] as num?)?.toDouble() ?? 100,
    batterySeriesCount: (json['batterySeriesCount'] as num?)?.toInt() ?? 1,
    batteryParallelCount: (json['batteryParallelCount'] as num?)?.toInt() ?? 1,
    batteryDoD: (json['batteryDoD'] as num?)?.toDouble() ?? 50,
    batteryEfficiencyPercent:
        (json['batteryEfficiencyPercent'] as num?)?.toDouble() ?? 85,
    inverterHeadroomPercent:
        (json['inverterHeadroomPercent'] as num?)?.toDouble() ?? 20,
    inverterSurgeMode: SurgeMode.fromName(json['inverterSurgeMode'] as String?),
    currencyLabel: json['currencyLabel'] as String? ?? '\$',
    pricePerKWh: (json['pricePerKWh'] as num?)?.toDouble(),
    fixedChargePerMonth: (json['fixedChargePerMonth'] as num?)?.toDouble(),
    estimatedSystemCost: (json['estimatedSystemCost'] as num?)?.toDouble(),
    selectedPanel: json['selectedPanel'] == null
        ? null
        : PanelSpec.fromJson(json['selectedPanel'] as Map<String, dynamic>),
    selectedBattery: json['selectedBattery'] == null
        ? null
        : BatteryEquipmentSpec.fromJson(
            json['selectedBattery'] as Map<String, dynamic>,
          ),
    selectedInverter: json['selectedInverter'] == null
        ? null
        : InverterSpec.fromJson(
            json['selectedInverter'] as Map<String, dynamic>,
          ),
    stringPanelsPerString:
        (json['stringPanelsPerString'] as num?)?.toInt() ?? 1,
    stringParallelStrings:
        (json['stringParallelStrings'] as num?)?.toInt() ?? 1,
    scenarios: (json['scenarios'] as List<dynamic>? ?? [])
        .map((e) => ProjectScenario.fromJson(e as Map<String, dynamic>))
        .toList(),
    activity: (json['activity'] as List<dynamic>? ?? [])
        .map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
