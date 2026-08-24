import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../core/units.dart';
import '../models/activity_entry.dart';
import '../models/appliance.dart';
import '../models/battery_chemistry.dart';
import '../models/battery_sizing_mode.dart';
import '../models/equipment_specs.dart';
import '../models/planning_inputs.dart';
import '../models/project.dart';
import '../models/results.dart';
import '../models/scenario.dart';
import '../models/surge_mode.dart';
import '../models/system_recommendation.dart';
import '../models/system_type.dart';
import '../services/battery_sizing_service.dart';
import '../services/energy_balance_service.dart';
import '../services/inverter_sizing_service.dart';
import '../services/load_calculation_service.dart';
import '../services/project_export_service.dart';
import '../services/project_repository.dart';
import '../services/solar_sizing_service.dart';
import '../services/system_recommendation_service.dart';
import '../services/tariff_service.dart';

/// Sort orders for the Projects list.
enum ProjectSortOrder { recentlyModified, recentlyCreated, name }

/// App-wide state: the list of saved projects, which one is active, and the
/// derived (calculated) results for the active project. All calculation
/// math is delegated to the dedicated services — this class only wires
/// inputs to outputs and persists state.
class ProjectProvider extends ChangeNotifier {
  final ProjectRepository _repository;
  final LoadCalculationService _loadService;
  final SolarSizingService _solarService;
  final BatterySizingService _batteryService;
  final InverterSizingService _inverterService;
  final EnergyBalanceService _energyBalanceService;
  final TariffService _tariffService;
  final SystemRecommendationService _recommendationService;
  final ProjectExportService _exportService;

  ProjectProvider({
    ProjectRepository? repository,
    LoadCalculationService? loadService,
    SolarSizingService? solarService,
    BatterySizingService? batteryService,
    InverterSizingService? inverterService,
    EnergyBalanceService? energyBalanceService,
    TariffService? tariffService,
    SystemRecommendationService? recommendationService,
    ProjectExportService? exportService,
  }) : _repository = repository ?? ProjectRepository(),
       _loadService = loadService ?? const LoadCalculationService(),
       _solarService = solarService ?? const SolarSizingService(),
       _batteryService = batteryService ?? const BatterySizingService(),
       _inverterService = inverterService ?? const InverterSizingService(),
       _energyBalanceService =
           energyBalanceService ?? const EnergyBalanceService(),
       _tariffService = tariffService ?? const TariffService(),
       _recommendationService =
           recommendationService ?? const SystemRecommendationService(),
       _exportService = exportService ?? const ProjectExportService() {
    _init();
  }

  List<SolarProject> _projects = [];
  String? _activeProjectId;
  bool _loading = true;

  Map<String, String?> fieldErrors = {};

  List<SolarProject> get projects => List.unmodifiable(_projects);
  bool get isLoading => _loading;
  bool get hasProjects => _projects.isNotEmpty;

  SolarProject? get activeProject {
    if (_activeProjectId == null) return null;
    final idx = _projects.indexWhere((p) => p.id == _activeProjectId);
    return idx == -1 ? null : _projects[idx];
  }

  // ---- Derived calculation results for the active project ----

  LoadProfile get loadProfile {
    final p = activeProject;
    if (p == null) return LoadProfile.empty;
    return _loadService.computeLoadProfile(p.appliances);
  }

  /// Load profile restricted to appliances marked "backup required" —
  /// drives battery and inverter backup planning.
  LoadProfile get essentialLoadProfile {
    final p = activeProject;
    if (p == null) return LoadProfile.empty;
    return _loadService.computeLoadProfile(
      p.appliances.where((a) => a.backupRequired).toList(),
    );
  }

  SolarArraySizing get solarArraySizing {
    final p = activeProject;
    if (p == null || fieldErrors.isNotEmpty) return SolarArraySizing.empty;
    return _solarService.computeArraySizing(
      dailyEnergyWh: loadProfile.dailyEnergyWh,
      peakSunHours: p.peakSunHours,
      systemEfficiencyPercent: p.systemEfficiencyPercent,
      panelWattage: p.panelWattage,
      designReservePercent: p.designReservePercent,
    );
  }

  BatteryBankSizing get batterySizing {
    final p = activeProject;
    if (p == null || fieldErrors.isNotEmpty) return BatteryBankSizing.empty;
    final essential = essentialLoadProfile;
    final backupLoadW = essential.enabledApplianceCount > 0
        ? essential.runningLoadW
        : loadProfile.runningLoadW;
    return _batteryService.computeBankSizing(
      essentialLoadW: backupLoadW,
      backupHours: p.backupHours,
      unitVoltage: p.batteryVoltage,
      unitAh: p.batteryAh,
      seriesCount: p.batterySeriesCount,
      parallelCount: p.batteryParallelCount,
      dodPercent: p.batteryDoD,
      batteryEfficiencyPercent: p.batteryEfficiencyPercent,
      designReservePercent: p.designReservePercent,
    );
  }

  InverterSizing get inverterSizing {
    final p = activeProject;
    if (p == null || fieldErrors.isNotEmpty) return InverterSizing.empty;
    final load = loadProfile;
    return _inverterService.computeInverterSizing(
      runningLoadW: load.runningLoadW,
      standardPeakLoadW: load.standardPeakLoadW,
      conservativePeakLoadW: load.conservativePeakLoadW,
      surgeMode: p.inverterSurgeMode,
      headroomPercent: p.inverterHeadroomPercent,
    );
  }

  EnergyBalanceResult get energyBalance {
    final array = solarArraySizing;
    return _energyBalanceService.computeBalance(
      dailyConsumptionWh: loadProfile.dailyEnergyWh,
      dailyGenerationWh: array.estimatedDailyGenerationWh,
    );
  }

  TariffEstimate get tariffEstimate {
    final p = activeProject;
    if (p == null) return TariffEstimate.empty;
    return _tariffService.computeTariffEstimate(
      monthlyConsumptionKWh: loadProfile.monthlyEnergyKWh,
      monthlySolarOffsetKWh: solarArraySizing.estimatedMonthlyGenerationKWh,
      pricePerKWh: p.pricePerKWh,
      fixedChargePerMonth: p.fixedChargePerMonth,
      currencyLabel: p.currencyLabel,
    );
  }

  PaybackEstimate get paybackEstimate {
    final p = activeProject;
    if (p == null) return PaybackEstimate.empty;
    return _tariffService.computeSimplePayback(
      systemCost: p.estimatedSystemCost,
      estimatedPotentialMonthlySavings:
          tariffEstimate.estimatedPotentialMonthlySavings,
    );
  }

  /// The complete, exportable planning result for the live project.
  SystemRecommendation? get systemRecommendation {
    final p = activeProject;
    if (p == null || fieldErrors.isNotEmpty) return null;
    return _recommendationService.build(
      projectName: p.name,
      appliances: p.appliances,
      inputs: p.toPlanningInputs(),
      currencyLabel: p.currencyLabel,
      pricePerKWh: p.pricePerKWh,
      fixedChargePerMonth: p.fixedChargePerMonth,
      estimatedSystemCost: p.estimatedSystemCost,
    );
  }

  /// Builds a recommendation for an arbitrary set of inputs (What-If /
  /// scenario comparison) without mutating the live project.
  SystemRecommendation? buildRecommendation(
    PlanningInputs inputs, {
    String? scenarioName,
  }) {
    final p = activeProject;
    if (p == null) return null;
    return _recommendationService.build(
      projectName: p.name,
      appliances: p.appliances,
      inputs: inputs,
      scenarioName: scenarioName,
      currencyLabel: p.currencyLabel,
      pricePerKWh: p.pricePerKWh,
      fixedChargePerMonth: p.fixedChargePerMonth,
      estimatedSystemCost: p.estimatedSystemCost,
    );
  }

  bool get hasValidResults =>
      activeProject != null &&
      fieldErrors.isEmpty &&
      loadProfile.dailyEnergyWh > 0;

  /// Simple checklist used for the Dashboard's project-completeness card.
  Map<String, bool> get completeness {
    final p = activeProject;
    if (p == null) return const {};
    final load = loadProfile;
    return {
      'Load Profile': load.enabledApplianceCount > 0,
      'Solar Resource': p.peakSunHours > 0,
      'Solar Array': solarArraySizing.recommendedArrayW > 0,
      'Battery': !p.systemType.batteryRequired || p.backupHours > 0,
      'Inverter': inverterSizing.recommendedInverterW > 0,
      'System Review': hasValidResults,
    };
  }

  // ---- Init / persistence ----

  Future<void> _init() async {
    _projects = await _repository.loadProjects();
    _activeProjectId = await _repository.loadActiveProjectId();
    if (_activeProjectId != null &&
        !_projects.any((p) => p.id == _activeProjectId)) {
      _activeProjectId = _projects.isEmpty ? null : _projects.first.id;
    }
    _revalidate();
    _loading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _repository.saveProjects(_projects);
    await _repository.saveActiveProjectId(_activeProjectId);
  }

  // ---- Project CRUD ----

  Future<SolarProject> createProject(
    String name, {
    double? defaultSystemEfficiencyPercent,
    double? defaultDesignReservePercent,
    double? defaultInverterHeadroomPercent,
    String? defaultCurrencyLabel,
  }) async {
    final project = SolarProject.create(
      name.trim().isEmpty ? 'Untitled Project' : name.trim(),
      defaultSystemEfficiencyPercent: defaultSystemEfficiencyPercent,
      defaultDesignReservePercent: defaultDesignReservePercent,
      defaultInverterHeadroomPercent: defaultInverterHeadroomPercent,
      defaultCurrencyLabel: defaultCurrencyLabel,
    );
    _projects = [..._projects, project];
    _activeProjectId = project.id;
    _revalidate();
    await _persist();
    notifyListeners();
    return project;
  }

  /// Projects filtered by name and sorted — used by the Projects screen's
  /// search/sort controls. Kept intentionally lightweight.
  List<SolarProject> searchProjects(String query, ProjectSortOrder order) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? List<SolarProject>.from(_projects)
        : _projects.where((p) => p.name.toLowerCase().contains(q)).toList();
    switch (order) {
      case ProjectSortOrder.recentlyModified:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case ProjectSortOrder.recentlyCreated:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProjectSortOrder.name:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }
    return filtered;
  }

  Future<void> deleteAllProjects() async {
    _projects = [];
    _activeProjectId = null;
    _revalidate();
    await _persist();
    notifyListeners();
  }

  Future<void> renameProject(String id, String newName) async {
    _updateProject(
      id,
      (p) => p.copyWith(name: newName.trim().isEmpty ? p.name : newName.trim()),
    );
    await _persist();
  }

  Future<SolarProject?> duplicateProject(String id) async {
    final idx = _projects.indexWhere((p) => p.id == id);
    if (idx == -1) return null;
    final copy = _projects[idx].duplicated();
    _projects = [..._projects, copy];
    _activeProjectId = copy.id;
    _revalidate();
    await _persist();
    notifyListeners();
    return copy;
  }

  Future<void> deleteProject(String id) async {
    _projects = _projects.where((p) => p.id != id).toList();
    if (_activeProjectId == id) {
      _activeProjectId = _projects.isEmpty ? null : _projects.first.id;
    }
    _revalidate();
    await _persist();
    notifyListeners();
  }

  void setActiveProject(String id) {
    if (!_projects.any((p) => p.id == id)) return;
    _activeProjectId = id;
    _revalidate();
    _repository.saveActiveProjectId(_activeProjectId);
    notifyListeners();
  }

  // ---- Appliance CRUD (on the active project) ----

  Future<void> addAppliance(Appliance appliance) async {
    _mutateAppliances((list) => [...list, appliance]);
    _logActivity('Appliance added: "${appliance.name}"');
    await _persist();
  }

  Future<void> updateAppliance(Appliance updated) async {
    _mutateAppliances(
      (list) => list.map((a) => a.id == updated.id ? updated : a).toList(),
    );
    await _persist();
  }

  Future<void> deleteAppliance(String id) async {
    final p = activeProject;
    Appliance? removed;
    if (p != null) {
      for (final a in p.appliances) {
        if (a.id == id) {
          removed = a;
          break;
        }
      }
    }
    _mutateAppliances((list) => list.where((a) => a.id != id).toList());
    if (removed != null) _logActivity('Appliance removed: "${removed.name}"');
    await _persist();
  }

  Future<void> duplicateAppliance(String id) async {
    _mutateAppliances((list) {
      final idx = list.indexWhere((a) => a.id == id);
      if (idx == -1) return list;
      final next = [...list];
      next.insert(idx + 1, list[idx].duplicated());
      return next;
    });
    await _persist();
  }

  Future<void> toggleApplianceEnabled(String id) async {
    _mutateAppliances(
      (list) => list
          .map((a) => a.id == id ? a.copyWith(enabled: !a.enabled) : a)
          .toList(),
    );
    await _persist();
  }

  Future<void> toggleApplianceBackupRequired(String id) async {
    _mutateAppliances(
      (list) => list
          .map(
            (a) =>
                a.id == id ? a.copyWith(backupRequired: !a.backupRequired) : a,
          )
          .toList(),
    );
    await _persist();
  }

  void _mutateAppliances(List<Appliance> Function(List<Appliance>) mutator) {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(appliances: mutator(proj.appliances)),
    );
  }

  /// Appends a human-readable activity entry to the active project's
  /// timeline — used only for structural changes, never per-keystroke edits.
  void _logActivity(String message) {
    final p = activeProject;
    if (p == null) return;
    _updateProject(p.id, (proj) => proj.copyWith(logActivity: message));
  }

  /// Records that a report was generated for the active project.
  Future<void> logReportGenerated() async {
    _logActivity('Report generated');
    await _persist();
  }

  // ---- System type / battery mode / chemistry / surge mode ----

  Future<void> setSystemType(SystemType type) async {
    final p = activeProject;
    if (p != null && p.systemType != type) {
      _updateProject(
        p.id,
        (proj) => proj.copyWith(
          systemType: type,
          logActivity: 'System type changed to ${type.label}',
        ),
      );
    }
    await _persist();
  }

  Future<void> setBatterySizingMode(BatterySizingMode mode) async {
    _updateProject(
      activeProject?.id ?? '',
      (p) => p.copyWith(batterySizingMode: mode),
    );
    await _persist();
  }

  /// Changing chemistry refreshes the DoD/efficiency *fields* with that
  /// chemistry's typical planning defaults — still fully editable
  /// afterwards, never presented as a fixed manufacturer spec.
  Future<void> setBatteryChemistry(BatteryChemistry chemistry) async {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(
        batteryChemistry: chemistry,
        batteryDoD: chemistry.defaultDoDPercent,
        batteryEfficiencyPercent: chemistry.defaultEfficiencyPercent,
        logActivity: 'Battery chemistry changed to ${chemistry.label}',
      ),
    );
    _rawFieldValues['batteryDoD'] = chemistry.defaultDoDPercent.toString();
    _rawFieldValues['batteryEfficiencyPercent'] = chemistry
        .defaultEfficiencyPercent
        .toString();
    fieldErrors.remove('batteryDoD');
    fieldErrors.remove('batteryEfficiencyPercent');
    await _persist();
  }

  Future<void> setInverterSurgeMode(SurgeMode mode) async {
    _updateProject(
      activeProject?.id ?? '',
      (p) => p.copyWith(inverterSurgeMode: mode),
    );
    await _persist();
  }

  Future<void> updateBatteryBankCount(String field, int delta) async {
    final p = activeProject;
    if (p == null) return;
    if (field == 'batterySeriesCount') {
      final next = (p.batterySeriesCount + delta).clamp(1, 100);
      _updateProject(p.id, (proj) => proj.copyWith(batterySeriesCount: next));
    } else if (field == 'batteryParallelCount') {
      final next = (p.batteryParallelCount + delta).clamp(1, 100);
      _updateProject(p.id, (proj) => proj.copyWith(batteryParallelCount: next));
    }
    await _persist();
  }

  /// Applies the automatic-sizing recommendation to the manual bank fields
  /// (series stays as configured; parallel strings adopt the recommended
  /// count) so the user can see and refine a concrete starting bank.
  Future<void> applyRecommendedBatteryBank() async {
    final p = activeProject;
    if (p == null) return;
    final recommended = batterySizing.recommendedParallelCount;
    if (recommended <= 0) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(batteryParallelCount: recommended),
    );
    await _persist();
  }

  // ---- Project setting fields (solar / battery / inverter / tariff assumptions) ----

  final Map<String, String> _rawFieldValues = {};

  String fieldValue(String field, String fallback) =>
      _rawFieldValues[field] ?? fallback;

  static const _optionalFields = {
    'panelVoltage',
    'panelCurrentAmps',
    'pricePerKWh',
    'fixedChargePerMonth',
    'estimatedSystemCost',
  };

  Future<void> updateSettingField(String field, String value) async {
    _rawFieldValues[field] = value;
    final p = activeProject;
    if (p == null) return;

    final parsed = double.tryParse(value);
    _validateField(field, value, parsed);

    if (value.isEmpty && _optionalFields.contains(field)) {
      final next = switch (field) {
        'panelVoltage' => p.copyWith(clearPanelVoltage: true),
        'panelCurrentAmps' => p.copyWith(clearPanelCurrent: true),
        'pricePerKWh' => p.copyWith(clearPricePerKWh: true),
        'fixedChargePerMonth' => p.copyWith(clearFixedCharge: true),
        'estimatedSystemCost' => p.copyWith(clearSystemCost: true),
        _ => p,
      };
      _updateProject(p.id, (_) => next);
      await _persist();
      return;
    }

    if (fieldErrors[field] == null && parsed != null) {
      SolarProject next = p;
      switch (field) {
        case 'peakSunHours':
          next = p.copyWith(peakSunHours: parsed);
          break;
        case 'systemEfficiencyPercent':
          next = p.copyWith(systemEfficiencyPercent: parsed);
          break;
        case 'designReservePercent':
          next = p.copyWith(designReservePercent: parsed);
          break;
        case 'panelWattage':
          next = p.copyWith(panelWattage: parsed);
          break;
        case 'panelVoltage':
          next = p.copyWith(panelVoltage: parsed);
          break;
        case 'panelCurrentAmps':
          next = p.copyWith(panelCurrentAmps: parsed);
          break;
        case 'backupHours':
          next = p.copyWith(backupHours: parsed);
          break;
        case 'batteryVoltage':
          next = p.copyWith(batteryVoltage: parsed);
          break;
        case 'batteryAh':
          next = p.copyWith(batteryAh: parsed);
          break;
        case 'batteryDoD':
          next = p.copyWith(batteryDoD: parsed);
          break;
        case 'batteryEfficiencyPercent':
          next = p.copyWith(batteryEfficiencyPercent: parsed);
          break;
        case 'inverterHeadroomPercent':
          next = p.copyWith(inverterHeadroomPercent: parsed);
          break;
        case 'pricePerKWh':
          next = p.copyWith(pricePerKWh: parsed);
          break;
        case 'fixedChargePerMonth':
          next = p.copyWith(fixedChargePerMonth: parsed);
          break;
        case 'estimatedSystemCost':
          next = p.copyWith(estimatedSystemCost: parsed);
          break;
      }
      _updateProject(p.id, (_) => next);
    } else {
      notifyListeners();
    }
    await _persist();
  }

  Future<void> updateCurrencyLabel(String value) async {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(currencyLabel: value.isEmpty ? '\$' : value),
    );
    await _persist();
  }

  void _validateField(String field, String value, double? parsed) {
    fieldErrors.remove(field);
    if (value.isEmpty) return;
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      if (!_optionalFields.contains(field) || value.isNotEmpty) {
        fieldErrors[field] = 'Enter a valid number';
      }
      return;
    }
    switch (field) {
      case 'peakSunHours':
        if (parsed <= 0) fieldErrors[field] = 'Must be > 0';
        break;
      case 'systemEfficiencyPercent':
        if (parsed <= 0 || parsed > 100) fieldErrors[field] = '1-100%';
        break;
      case 'designReservePercent':
        if (parsed < 0) fieldErrors[field] = 'Must be >= 0';
        break;
      case 'panelWattage':
        if (parsed <= 0) fieldErrors[field] = 'Must be > 0';
        break;
      case 'backupHours':
        if (parsed < 0) fieldErrors[field] = 'Must be >= 0';
        break;
      case 'batteryVoltage':
        if (parsed <= 0) fieldErrors[field] = 'Must be > 0';
        break;
      case 'batteryAh':
        if (parsed <= 0) fieldErrors[field] = 'Must be > 0';
        break;
      case 'batteryDoD':
        if (parsed <= 0 || parsed > 100) fieldErrors[field] = '1-100%';
        break;
      case 'batteryEfficiencyPercent':
        if (parsed <= 0 || parsed > 100) fieldErrors[field] = '1-100%';
        break;
      case 'inverterHeadroomPercent':
        if (parsed < 0 || parsed >= 95) fieldErrors[field] = '0-94%';
        break;
      case 'pricePerKWh':
      case 'fixedChargePerMonth':
      case 'estimatedSystemCost':
        if (parsed < 0) fieldErrors[field] = 'Must be >= 0';
        break;
    }
  }

  void _revalidate() {
    fieldErrors = {};
    final p = activeProject;
    if (p == null) return;
    _rawFieldValues['peakSunHours'] = p.peakSunHours.toString();
    _rawFieldValues['systemEfficiencyPercent'] = p.systemEfficiencyPercent
        .toString();
    _rawFieldValues['designReservePercent'] = p.designReservePercent.toString();
    _rawFieldValues['panelWattage'] = p.panelWattage.toString();
    _rawFieldValues['panelVoltage'] = p.panelVoltage?.toString() ?? '';
    _rawFieldValues['panelCurrentAmps'] = p.panelCurrentAmps?.toString() ?? '';
    _rawFieldValues['backupHours'] = p.backupHours.toString();
    _rawFieldValues['batteryVoltage'] = p.batteryVoltage.toString();
    _rawFieldValues['batteryAh'] = p.batteryAh.toString();
    _rawFieldValues['batteryDoD'] = p.batteryDoD.toString();
    _rawFieldValues['batteryEfficiencyPercent'] = p.batteryEfficiencyPercent
        .toString();
    _rawFieldValues['inverterHeadroomPercent'] = p.inverterHeadroomPercent
        .toString();
    _rawFieldValues['pricePerKWh'] = p.pricePerKWh?.toString() ?? '';
    _rawFieldValues['fixedChargePerMonth'] =
        p.fixedChargePerMonth?.toString() ?? '';
    _rawFieldValues['estimatedSystemCost'] =
        p.estimatedSystemCost?.toString() ?? '';
  }

  void _updateProject(String id, SolarProject Function(SolarProject) update) {
    final idx = _projects.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final next = [..._projects];
    next[idx] = update(next[idx]).copyWith(updatedAt: DateTime.now());
    _projects = next;
    notifyListeners();
  }

  // ---- Scenarios (What-If / comparison) ----

  Future<ProjectScenario?> saveScenario(
    String name,
    PlanningInputs inputs,
  ) async {
    final p = activeProject;
    if (p == null) return null;
    final scenario = ProjectScenario.create(
      name.trim().isEmpty ? 'Scenario ${p.scenarios.length + 1}' : name.trim(),
      inputs,
    );
    _updateProject(
      p.id,
      (proj) => proj.copyWith(
        scenarios: [...proj.scenarios, scenario],
        logActivity: 'Scenario "${scenario.name}" created',
      ),
    );
    await _persist();
    return scenario;
  }

  Future<void> renameScenario(String id, String newName) async {
    final p = activeProject;
    if (p == null || newName.trim().isEmpty) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(
        scenarios: proj.scenarios
            .map(
              (s) => s.id == id
                  ? ProjectScenario(
                      id: s.id,
                      name: newName.trim(),
                      createdAt: s.createdAt,
                      inputs: s.inputs,
                    )
                  : s,
            )
            .toList(),
      ),
    );
    await _persist();
  }

  Future<ProjectScenario?> duplicateScenario(String id) async {
    final p = activeProject;
    if (p == null) return null;
    ProjectScenario? source;
    for (final s in p.scenarios) {
      if (s.id == id) {
        source = s;
        break;
      }
    }
    if (source == null) return null;
    final copy = ProjectScenario.create('${source.name} (copy)', source.inputs);
    _updateProject(
      p.id,
      (proj) => proj.copyWith(scenarios: [...proj.scenarios, copy]),
    );
    await _persist();
    return copy;
  }

  Future<void> deleteScenario(String id) async {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(
        scenarios: proj.scenarios.where((s) => s.id != id).toList(),
      ),
    );
    await _persist();
  }

  /// Applies a saved scenario's inputs to the live project.
  Future<void> applyScenario(String id) async {
    final p = activeProject;
    if (p == null) return;
    ProjectScenario? scenario;
    for (final s in p.scenarios) {
      if (s.id == id) {
        scenario = s;
        break;
      }
    }
    if (scenario == null) return;
    await applyPlanningInputs(
      scenario.inputs,
      activityMessage: 'Scenario "${scenario.name}" applied',
    );
  }

  /// Applies an arbitrary [PlanningInputs] bundle (e.g. from a What-If
  /// exploration or a saved scenario) to the live project. The project is
  /// only ever mutated when the user explicitly chooses to apply — What-If
  /// itself never touches the provider until this is called, and the UI
  /// requires a deliberate confirmation before calling this for a scenario.
  Future<void> applyPlanningInputs(
    PlanningInputs i, {
    String? activityMessage,
  }) async {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(
        systemType: i.systemType,
        peakSunHours: i.peakSunHours,
        systemEfficiencyPercent: i.systemEfficiencyPercent,
        designReservePercent: i.designReservePercent,
        panelWattage: i.panelWattage,
        batterySizingMode: i.batterySizingMode,
        backupHours: i.backupHours,
        batteryChemistry: i.batteryChemistry,
        batteryVoltage: i.batteryUnitVoltage,
        batteryAh: i.batteryUnitAh,
        batterySeriesCount: i.batterySeriesCount,
        batteryParallelCount: i.batteryParallelCount,
        batteryDoD: i.batteryDoD,
        batteryEfficiencyPercent: i.batteryEfficiencyPercent,
        inverterHeadroomPercent: i.inverterHeadroomPercent,
        inverterSurgeMode: i.inverterSurgeMode,
        logActivity:
            activityMessage ?? 'Planning assumptions updated from What-If',
      ),
    );
    _revalidate();
    await _persist();
  }

  // ---- Sharing ----

  void shareResults() {
    final rec = systemRecommendation;
    if (rec == null || !hasValidResults) return;
    final load = rec.loadProfile;
    final array = rec.solarArraySizing;
    final inverter = rec.inverterSizing;
    final battery = rec.batterySizing;

    String text =
        'Solar System Estimate — ${rec.projectName}\n\n'
        'Load:\n'
        '- Connected Load: ${Units.formatWatts(load.connectedLoadW)}\n'
        '- Daily Consumption: ${Units.formatWh(load.dailyEnergyWh)}\n'
        '- Monthly Consumption: ${Units.formatKwh(load.monthlyEnergyKWh)}\n\n'
        'Solar Array:\n'
        '- Calculated Minimum: ${Units.formatWatts(array.requiredArrayW)}\n'
        '- Recommended: ${Units.formatWatts(array.recommendedArrayW)}\n'
        '- Panels: ${array.panelCount} x ${array.panelWattage.toInt()}W\n\n'
        'Inverter:\n'
        '- Running Load: ${Units.formatWatts(inverter.runningLoadW)}\n'
        '- Recommended: ${Units.formatWatts(inverter.recommendedInverterW)}\n';

    if (battery.backupEnabled) {
      text +=
          '\nBattery:\n'
          '- Backup Duration: ${battery.backupHours.toStringAsFixed(0)}h\n'
          '- Bank: ${battery.bankVoltage.toInt()}V ${battery.bankAh.toInt()}Ah '
          '(${battery.seriesCount}S${battery.parallelCount}P)\n'
          '- Usable Storage: ${Units.formatWh(battery.usableBankWh)}\n'
          '- ${battery.status.label}';
    }

    text +=
        '\n\nEstimates only — actual requirements vary with equipment and conditions.';

    Share.share(text, subject: 'Solar System Estimate — ${rec.projectName}');
  }

  /// A short, spam-free plain-text summary suitable for the native share
  /// sheet (message apps, notes, etc.) — separate from the full [shareResults].
  void shareSummary() {
    final rec = systemRecommendation;
    if (rec == null || !hasValidResults) return;
    final array = rec.solarArraySizing;
    final battery = rec.batterySizing;
    final inverter = rec.inverterSizing;

    final text =
        'Solar Project: ${rec.projectName}\n'
        'Daily Energy: ${Units.formatWh(rec.loadProfile.dailyEnergyWh)}\n'
        'Recommended Solar: ${Units.formatWatts(array.recommendedArrayW)}\n'
        'Panels: ${array.panelCount} x ${array.panelWattage.toInt()}W\n'
        '${battery.backupEnabled ? 'Battery: ${Units.formatWh(battery.usableBankWh)} usable\n' : ''}'
        'Inverter Planning Capacity: ${Units.formatWatts(inverter.recommendedInverterW)}\n\n'
        'Generated using Solar Calculator.';

    Share.share(text, subject: 'Solar Project: ${rec.projectName}');
  }

  // ---- Project workspace details (description, notes, status, etc.) ----

  Future<void> updateProjectDetails({
    String? description,
    String? projectType,
    String? siteLabel,
    String? clientReference,
    String? installationNotes,
    String? notes,
  }) async {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(
        description: description,
        projectType: projectType,
        siteLabel: siteLabel,
        clientReference: clientReference,
        installationNotes: installationNotes,
        notes: notes,
      ),
    );
    await _persist();
  }

  Future<void> setManuallyReviewed(bool reviewed) async {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(
        manuallyReviewed: reviewed,
        logActivity: reviewed
            ? 'Project marked as Reviewed'
            : 'Project review mark cleared',
      ),
    );
    await _persist();
  }

  // ---- Equipment Workspace ----

  Future<void> setSelectedPanel(PanelSpec? spec) async {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) =>
          proj.copyWith(selectedPanel: spec, clearSelectedPanel: spec == null),
    );
    await _persist();
  }

  Future<void> setSelectedBattery(BatteryEquipmentSpec? spec) async {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(
        selectedBattery: spec,
        clearSelectedBattery: spec == null,
      ),
    );
    await _persist();
  }

  Future<void> setSelectedInverter(InverterSpec? spec) async {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(
        selectedInverter: spec,
        clearSelectedInverter: spec == null,
      ),
    );
    await _persist();
  }

  Future<void> setStringLayout(int panelsPerString, int parallelStrings) async {
    final p = activeProject;
    if (p == null) return;
    _updateProject(
      p.id,
      (proj) => proj.copyWith(
        stringPanelsPerString: panelsPerString.clamp(1, 200),
        stringParallelStrings: parallelStrings.clamp(1, 200),
      ),
    );
    await _persist();
  }

  // ---- Project export / import ----

  String exportActiveProjectJson() {
    final p = activeProject;
    if (p == null) throw StateError('No active project to export.');
    return _exportService.exportProjectToJsonString(p);
  }

  /// Imports a project from an exported JSON string, creating it as a new
  /// local project (never silently overwriting an existing one). Throws
  /// [ProjectImportException] with a human-readable message on invalid input.
  Future<SolarProject> importProjectJson(String jsonString) async {
    final imported = _exportService.importProjectFromJsonString(jsonString);
    final now = DateTime.now();
    final asNew = SolarProject(
      id: const Uuid().v4(),
      name: imported.name,
      createdAt: now,
      updatedAt: now,
      description: imported.description,
      projectType: imported.projectType,
      siteLabel: imported.siteLabel,
      clientReference: imported.clientReference,
      installationNotes: imported.installationNotes,
      notes: imported.notes,
      appliances: imported.appliances,
      systemType: imported.systemType,
      peakSunHours: imported.peakSunHours,
      systemEfficiencyPercent: imported.systemEfficiencyPercent,
      designReservePercent: imported.designReservePercent,
      panelWattage: imported.panelWattage,
      panelVoltage: imported.panelVoltage,
      panelCurrentAmps: imported.panelCurrentAmps,
      batterySizingMode: imported.batterySizingMode,
      backupHours: imported.backupHours,
      batteryChemistry: imported.batteryChemistry,
      batteryVoltage: imported.batteryVoltage,
      batteryAh: imported.batteryAh,
      batterySeriesCount: imported.batterySeriesCount,
      batteryParallelCount: imported.batteryParallelCount,
      batteryDoD: imported.batteryDoD,
      batteryEfficiencyPercent: imported.batteryEfficiencyPercent,
      inverterHeadroomPercent: imported.inverterHeadroomPercent,
      inverterSurgeMode: imported.inverterSurgeMode,
      currencyLabel: imported.currencyLabel,
      pricePerKWh: imported.pricePerKWh,
      fixedChargePerMonth: imported.fixedChargePerMonth,
      estimatedSystemCost: imported.estimatedSystemCost,
      selectedPanel: imported.selectedPanel,
      selectedBattery: imported.selectedBattery,
      selectedInverter: imported.selectedInverter,
      stringPanelsPerString: imported.stringPanelsPerString,
      stringParallelStrings: imported.stringParallelStrings,
      scenarios: imported.scenarios,
      activity: [ActivityEntry(timestamp: now, message: 'Project imported')],
    );
    _projects = [..._projects, asNew];
    _activeProjectId = asNew.id;
    _revalidate();
    await _persist();
    notifyListeners();
    return asNew;
  }
}
