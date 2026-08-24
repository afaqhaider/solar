import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/units.dart';
import '../../models/project.dart';
import '../../models/system_recommendation.dart';
import '../../models/system_type.dart';
import '../../state/project_provider.dart';
import '../../state/tab_controller.dart';
import '../widgets/design_status_badge.dart';
import '../widgets/disclaimer.dart';
import '../widgets/empty_state.dart';
import '../widgets/energy_flow_diagram.dart';
import '../widgets/info_explainer.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';
import 'analysis_screen.dart';
import 'assumptions_screen.dart';
import 'equipment_screen.dart';
import 'project_details_screen.dart';
import 'projects_screen.dart' show showCreateProjectDialog;
import 'report_screen.dart';
import 'scenarios_screen.dart';
import 'what_if_screen.dart';

const double _wideBreakpoint = 900;

/// Complete recommended system configuration — the synthesis screen that
/// pulls together Loads, Solar, Battery and Inverter into one shareable
/// planning summary, with an iPad-specific 3-column layout.
class SystemScreen extends StatelessWidget {
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System'),
        actions: [
          Consumer<ProjectProvider>(
            builder: (context, provider, _) {
              if (provider.activeProject == null) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.compare_arrows),
                    tooltip: 'What-If',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WhatIfScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmarks_outlined),
                    tooltip: 'Scenarios',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ScenariosScreen(),
                      ),
                    ),
                  ),
                  if (provider.hasValidResults)
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: provider.shareResults,
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.activeProject;
          if (project == null) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'No active project',
                  message:
                      'Create a project first to see a system recommendation.',
                  actionLabel: 'New Project',
                  onAction: () => showCreateProjectDialog(context),
                ),
              ),
            );
          }

          final rec = provider.systemRecommendation;
          if (rec == null || rec.loadProfile.dailyEnergyWh <= 0) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.info_outline,
                  title: 'Not enough information yet',
                  message:
                      'Add appliances in Loads to generate a full system recommendation.',
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= _wideBreakpoint;
              return isWide
                  ? _WideSystemLayout(project: project, rec: rec)
                  : _CompactSystemLayout(project: project, rec: rec);
            },
          );
        },
      ),
    );
  }
}

// ---- Shared section builders ----

List<Widget> _headerSections(
  BuildContext context,
  ProjectProvider provider,
  SolarProject project,
) {
  return [
    Text(
      project.name,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 4),
    const Text(
      'Recommended system based on your current load profile and assumptions.',
      style: TextStyle(fontSize: 12, color: Colors.grey),
    ),
    const SizedBox(height: 16),
    _SystemTypeSelector(project: project),
    const SizedBox(height: 16),
    _WorkflowChecklist(provider: provider),
  ];
}

class _WorkspaceHub extends StatelessWidget {
  const _WorkspaceHub();

  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, WidgetBuilder)>[
      ('Equipment', Icons.inventory_2_outlined, (_) => const EquipmentScreen()),
      ('Analysis', Icons.analytics_outlined, (_) => const AnalysisScreen()),
      ('Assumptions', Icons.tune, (_) => const AssumptionsScreen()),
      (
        'Project Details',
        Icons.description_outlined,
        (_) => const ProjectDetailsScreen(),
      ),
      ('Report', Icons.picture_as_pdf_outlined, (_) => const ReportScreen()),
    ];
    return SectionCard(
      title: 'Workspace',
      icon: Icons.workspaces_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            OutlinedButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: item.$3)),
              icon: Icon(item.$2, size: 16),
              label: Text(item.$1, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

Widget _energySection(SystemRecommendation rec) {
  final load = rec.loadProfile;
  final essential = rec.essentialLoadProfile;
  return SectionCard(
    title: 'Energy',
    icon: Icons.bolt,
    child: Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        MetricTile(
          label: 'Connected load',
          value: Units.formatWatts(load.connectedLoadW),
        ),
        MetricTile(
          label: 'Estimated peak load',
          value: Units.formatWatts(load.conservativePeakLoadW),
        ),
        MetricTile(
          label: 'Daily energy',
          value: Units.formatWh(load.dailyEnergyWh),
        ),
        MetricTile(
          label: 'Monthly energy',
          value: Units.formatKwh(load.monthlyEnergyKWh),
        ),
        if (essential.enabledApplianceCount > 0)
          MetricTile(
            label: 'Essential backup load',
            value: Units.formatWatts(essential.runningLoadW),
          ),
      ],
    ),
  );
}

Widget _solarSection(SystemRecommendation rec) {
  final array = rec.solarArraySizing;
  return SectionCard(
    title: 'Solar',
    icon: Icons.wb_sunny,
    child: Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        MetricTile(
          label: 'Calculated minimum',
          value: Units.formatWatts(array.requiredArrayW),
        ),
        MetricTile(
          label: 'Recommended array',
          value: Units.formatWatts(array.recommendedArrayW),
        ),
        MetricTile(
          label: 'Panel wattage',
          value: '${array.panelWattage.toInt()} W',
        ),
        MetricTile(label: 'Estimated panels', value: '${array.panelCount}'),
        MetricTile(
          label: 'Est. generation',
          value: '${Units.formatKwh(array.estimatedMonthlyGenerationKWh)}/mo',
        ),
      ],
    ),
  );
}

Widget _batterySection(SystemRecommendation rec) {
  final battery = rec.batterySizing;
  return SectionCard(
    title: 'Battery',
    icon: Icons.battery_charging_full,
    trailing: battery.backupEnabled
        ? DesignStatusBadge(status: battery.status)
        : null,
    child: battery.backupEnabled
        ? Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              MetricTile(
                label: 'Target backup',
                value: '${battery.backupHours.toStringAsFixed(0)} h',
              ),
              MetricTile(
                label: 'Bank configuration',
                value: '${battery.seriesCount}S${battery.parallelCount}P',
              ),
              MetricTile(
                label: 'Required (usable)',
                value: Units.formatWh(battery.requiredUsableWh),
              ),
              MetricTile(
                label: 'Required (nominal)',
                value: Units.formatWh(battery.requiredNominalWh),
              ),
              MetricTile(
                label: 'Usable storage',
                value: Units.formatWh(battery.usableBankWh),
              ),
              MetricTile(
                label: 'Estimated autonomy',
                value: '${battery.estimatedRuntimeHours.toStringAsFixed(1)} h',
              ),
            ],
          )
        : const Text(
            'Not configured — set a backup duration in Battery.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
  );
}

Widget _inverterSection(SystemRecommendation rec) {
  final inverter = rec.inverterSizing;
  return SectionCard(
    title: 'Inverter',
    icon: Icons.dns,
    child: Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        MetricTile(
          label: 'Running load',
          value: Units.formatWatts(inverter.runningLoadW),
        ),
        MetricTile(
          label: 'Estimated surge load',
          value: Units.formatWatts(inverter.surgeLoadW),
        ),
        MetricTile(
          label: 'Calculated minimum',
          value: Units.formatWatts(inverter.minInverterW),
        ),
        MetricTile(
          label: 'Planning capacity',
          value: Units.formatWatts(inverter.recommendedInverterW),
        ),
      ],
    ),
  );
}

Widget _energyBalanceSection(SystemRecommendation rec) {
  final balance = rec.energyBalance;
  final coveragePercent = balance.coveragePercent.clamp(0, 999);
  return SectionCard(
    title: 'Energy Balance',
    icon: Icons.balance,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (coveragePercent / 100).clamp(0, 1).toDouble(),
            minHeight: 8,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            MetricTile(
              label: 'Daily consumption',
              value: Units.formatWh(balance.dailyConsumptionWh),
            ),
            MetricTile(
              label: 'Est. daily generation',
              value: Units.formatWh(balance.dailyGenerationWh),
            ),
            MetricTile(
              label: balance.surplusWh >= 0
                  ? 'Estimated surplus'
                  : 'Estimated shortfall',
              value: Units.formatWh(balance.surplusWh.abs()),
            ),
            MetricTile(
              label: 'Coverage of consumption',
              value: '${coveragePercent.toStringAsFixed(0)}%',
            ),
          ],
        ),
        if (rec.assumptions.systemType == SystemType.offGrid &&
            balance.surplusWh < 0) ...[
          const SizedBox(height: 8),
          Text(
            'Estimated generation falls short of estimated consumption for an off-grid system — '
            'this does not necessarily mean the system will fail, but it is worth reviewing array '
            'size, panel wattage, or connected load.',
            style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
          ),
        ],
      ],
    ),
  );
}

class _TariffInputsCard extends StatelessWidget {
  final SolarProject project;
  const _TariffInputsCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    return SectionCard(
      title: 'Electricity Tariff (optional)',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: project.currencyLabel)
                    ..selection = TextSelection.collapsed(
                      offset: project.currencyLabel.length,
                    ),
                  onChanged: provider.updateCurrencyLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TariffField(
                  label: 'Price per kWh',
                  field: 'pricePerKWh',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TariffField(
            label: 'Fixed charge per month (optional)',
            field: 'fixedChargePerMonth',
          ),
          const SizedBox(height: 8),
          _TariffField(
            label: 'Estimated system cost (optional)',
            field: 'estimatedSystemCost',
          ),
          const SizedBox(height: 4),
          const Text(
            'Used only for an estimated savings/payback figure — never presented as a guarantee.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _TariffField extends StatelessWidget {
  final String label;
  final String field;
  const _TariffField({required this.label, required this.field});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final value = provider.fieldValue(field, '');
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        errorText: provider.fieldErrors[field],
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: (v) => provider.updateSettingField(field, v),
    );
  }
}

Widget? _tariffSection(SystemRecommendation rec) {
  final tariff = rec.tariffEstimate;
  if (!tariff.configured) return null;
  final payback = rec.paybackEstimate;
  return SectionCard(
    title: 'Estimated Electricity Savings',
    icon: Icons.savings_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            MetricTile(
              label: 'Estimated current monthly cost',
              value:
                  '${tariff.currencyLabel}${tariff.estimatedCurrentMonthlyCost.toStringAsFixed(2)}',
            ),
            MetricTile(
              label: 'Estimated solar offset',
              value: Units.formatKwh(tariff.estimatedSolarOffsetKWhPerMonth),
            ),
            MetricTile(
              label: 'Estimated potential savings/mo',
              value:
                  '${tariff.currencyLabel}${tariff.estimatedPotentialMonthlySavings.toStringAsFixed(2)}',
            ),
            if (payback.configured)
              MetricTile(
                label: 'Simple payback estimate',
                value: payback.estimatedPaybackYears != null
                    ? '${payback.estimatedPaybackYears!.toStringAsFixed(1)} yrs'
                    : 'N/A',
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Estimated Potential Savings — not a guarantee. This simple estimate does not account '
          'for financing, maintenance, degradation, tariff changes, taxes, incentives, or '
          'opportunity cost, and is not investment advice.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    ),
  );
}

Widget _assumptionsSection(SystemRecommendation rec) {
  final i = rec.assumptions;
  return SectionCard(
    title: 'Assumptions',
    icon: Icons.list_alt,
    child: Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        MetricTile(label: 'Peak sun hours', value: '${i.peakSunHours} h/day'),
        MetricTile(
          label: 'System efficiency',
          value: '${i.systemEfficiencyPercent}%',
        ),
        MetricTile(
          label: 'Design reserve',
          value: '${i.designReservePercent}%',
        ),
        MetricTile(label: 'Battery DoD', value: '${i.batteryDoD}%'),
        MetricTile(
          label: 'Battery efficiency',
          value: '${i.batteryEfficiencyPercent}%',
        ),
        MetricTile(
          label: 'Inverter headroom',
          value: '${i.inverterHeadroomPercent}%',
        ),
      ],
    ),
  );
}

Widget _systemEducationCard() {
  return const EducationCard(
    title: 'System types & planning concepts',
    items: [
      InfoExplainer(
        term: 'Grid-tied solar',
        explanation:
            'Primarily solar generation with utility grid availability; battery storage is optional.',
      ),
      InfoExplainer(
        term: 'Hybrid solar',
        explanation:
            'Solar generation with battery storage and the utility grid as a backstop.',
      ),
      InfoExplainer(
        term: 'Off-grid solar',
        explanation:
            'Solar generation with battery storage and no assumption of continuous grid support.',
      ),
      InfoExplainer(
        term: 'System efficiency',
        explanation:
            'Accounts for wiring, inverter conversion and soiling losses between panels and usable energy.',
      ),
      InfoExplainer(
        term: 'Design reserve',
        explanation:
            'Extra margin added on top of a calculated minimum to absorb cloudy days or future load growth.',
      ),
    ],
  );
}

class _CompactSystemLayout extends StatelessWidget {
  final SolarProject project;
  final SystemRecommendation rec;
  const _CompactSystemLayout({required this.project, required this.rec});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProjectProvider>();
    final tariffSection = _tariffSection(rec);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ..._headerSections(context, provider, project),
        const SizedBox(height: 16),
        const _WorkspaceHub(),
        const SizedBox(height: 16),
        EnergyFlowDiagram(
          systemType: project.systemType,
          hasBattery: rec.batterySizing.backupEnabled,
        ),
        const SizedBox(height: 16),
        _energySection(rec),
        const SizedBox(height: 12),
        _solarSection(rec),
        const SizedBox(height: 12),
        _batterySection(rec),
        const SizedBox(height: 12),
        _inverterSection(rec),
        const SizedBox(height: 12),
        _energyBalanceSection(rec),
        const SizedBox(height: 12),
        _TariffInputsCard(project: project),
        if (tariffSection != null) ...[
          const SizedBox(height: 12),
          tariffSection,
        ],
        const SizedBox(height: 12),
        _assumptionsSection(rec),
        const SizedBox(height: 12),
        _systemEducationCard(),
        const SizedBox(height: 20),
        const DisclaimerText(text: SystemRecommendation.disclaimer),
      ],
    );
  }
}

class _WideSystemLayout extends StatelessWidget {
  final SolarProject project;
  final SystemRecommendation rec;
  const _WideSystemLayout({required this.project, required this.rec});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProjectProvider>();
    final tariffSection = _tariffSection(rec);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._headerSections(context, provider, project),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: assumptions + energy flow
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const _WorkspaceHub(),
                      const SizedBox(height: 12),
                      EnergyFlowDiagram(
                        systemType: project.systemType,
                        hasBattery: rec.batterySizing.backupEnabled,
                      ),
                      const SizedBox(height: 12),
                      _assumptionsSection(rec),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // CENTER: solar + battery recommendation
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _energySection(rec),
                      const SizedBox(height: 12),
                      _solarSection(rec),
                      const SizedBox(height: 12),
                      _batterySection(rec),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // RIGHT: inverter + energy balance (+ tariff)
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _inverterSection(rec),
                      const SizedBox(height: 12),
                      _energyBalanceSection(rec),
                      const SizedBox(height: 12),
                      _TariffInputsCard(project: project),
                      if (tariffSection != null) ...[
                        const SizedBox(height: 12),
                        tariffSection,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _systemEducationCard(),
          const SizedBox(height: 20),
          const DisclaimerText(text: SystemRecommendation.disclaimer),
        ],
      ),
    );
  }
}

class _SystemTypeSelector extends StatelessWidget {
  final SolarProject project;
  const _SystemTypeSelector({required this.project});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProjectProvider>();
    return SectionCard(
      title: 'System Type',
      icon: Icons.hub_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<SystemType>(
            segments: SystemType.values
                .map((t) => ButtonSegment(value: t, label: Text(t.label)))
                .toList(),
            selected: {project.systemType},
            onSelectionChanged: (s) => provider.setSystemType(s.first),
          ),
          const SizedBox(height: 8),
          Text(
            project.systemType.description,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _WorkflowChecklist extends StatelessWidget {
  final ProjectProvider provider;
  const _WorkflowChecklist({required this.provider});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Load Profile', SolarTabController.loads),
      ('Solar Resource', SolarTabController.solar),
      ('Solar Array', SolarTabController.solar),
      ('Battery', SolarTabController.battery),
      ('Inverter', SolarTabController.inverter),
      ('System Review', SolarTabController.system),
    ];
    final completeness = provider.completeness;
    final batteryOptional =
        !(provider.activeProject?.systemType.batteryRequired ?? true);

    return SectionCard(
      title: 'Guided Workflow',
      icon: Icons.checklist,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final step in steps)
            ActionChip(
              avatar: Icon(
                (step.$1 == 'Battery' && batteryOptional)
                    ? Icons.remove_circle_outline
                    : (completeness[step.$1] ?? false)
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 16,
                color: (step.$1 == 'Battery' && batteryOptional)
                    ? Colors.grey
                    : (completeness[step.$1] ?? false)
                    ? Colors.green
                    : Colors.grey,
              ),
              label: Text(
                (step.$1 == 'Battery' && batteryOptional)
                    ? '${step.$1} (Optional)'
                    : step.$1,
                style: const TextStyle(fontSize: 11),
              ),
              onPressed: () => context.read<SolarTabController>().goTo(step.$2),
            ),
        ],
      ),
    );
  }
}
