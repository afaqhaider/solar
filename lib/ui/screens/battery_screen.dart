import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/units.dart';
import '../../models/battery_chemistry.dart';
import '../../models/battery_sizing_mode.dart';
import '../../state/project_provider.dart';
import '../widgets/calculation_explanation.dart';
import '../widgets/design_status_badge.dart';
import '../widgets/disclaimer.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_explainer.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';
import 'projects_screen.dart' show showCreateProjectDialog;

const List<double> _backupPresets = [1, 2, 4, 6, 8, 12];

/// Battery Storage Planner: automatic sizing from the Essential Load
/// Profile, or manual bank evaluation, with series/parallel configuration.
class BatteryScreen extends StatelessWidget {
  const BatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battery')),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.activeProject;
          if (project == null) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.battery_charging_full_outlined,
                  title: 'No active project',
                  message: 'Create a project first to plan battery backup.',
                  actionLabel: 'New Project',
                  onAction: () => showCreateProjectDialog(context),
                ),
              ),
            );
          }

          final essential = provider.essentialLoadProfile;
          final battery = provider.batterySizing;
          final backupHours =
              double.tryParse(provider.fieldValue('backupHours', '0')) ?? 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (!project.systemType.batteryRequired)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Battery storage is optional for a Grid-Tied system.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              SectionHeader(
                title: 'Essential Load',
                icon: Icons.shield_outlined,
              ),
              SectionCard(
                title: 'What needs backup power',
                icon: Icons.shield,
                child: essential.enabledApplianceCount == 0
                    ? const Text(
                        'No appliances are marked "Backup required" yet. Go to Loads and mark '
                        'essentials (fridge, lights, router) to target battery sizing at them '
                        'instead of your entire connected load.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          MetricTile(
                            label: 'Essential backup load',
                            value: Units.formatWatts(essential.runningLoadW),
                          ),
                          MetricTile(
                            label: 'Essential daily energy',
                            value: Units.formatWh(essential.dailyEnergyWh),
                          ),
                          MetricTile(
                            label: 'Appliances included',
                            value: '${essential.enabledApplianceCount}',
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              SectionHeader(title: 'Backup Duration', icon: Icons.timelapse),
              SectionCard(
                title: 'Target backup period',
                icon: Icons.timelapse,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final h in _backupPresets)
                          ChoiceChip(
                            label: Text('${h.toInt()}h'),
                            selected: backupHours == h,
                            onSelected: (_) => provider.updateSettingField(
                              'backupHours',
                              h.toString(),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      label: 'Custom backup duration',
                      field: 'backupHours',
                      suffix: 'h',
                    ),
                    if (backupHours > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Estimated storage required for ${backupHours.toStringAsFixed(backupHours == backupHours.roundToDouble() ? 0 : 1)} '
                        'hours of selected backup loads.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionHeader(
                title: 'Battery Specification',
                icon: Icons.battery_std,
              ),
              SectionCard(
                title: 'Chemistry & planning assumptions',
                icon: Icons.science_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<BatteryChemistry>(
                      initialValue: project.batteryChemistry,
                      decoration: const InputDecoration(
                        labelText: 'Battery chemistry',
                        border: OutlineInputBorder(),
                      ),
                      items: BatteryChemistry.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: (c) {
                        if (c != null) provider.setBatteryChemistry(c);
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Selecting a chemistry fills in typical planning DoD/efficiency values below — '
                      'these are editable assumptions, not guaranteed manufacturer specifications.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            label: 'Depth of discharge',
                            field: 'batteryDoD',
                            suffix: '%',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NumberField(
                            label: 'Battery efficiency',
                            field: 'batteryEfficiencyPercent',
                            suffix: '%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      label: 'Design reserve',
                      field: 'designReservePercent',
                      suffix: '%',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionHeader(
                title: 'Bank Configuration',
                icon: Icons.view_module_outlined,
              ),
              SectionCard(
                title: 'Sizing mode',
                icon: Icons.tune,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<BatterySizingMode>(
                      segments: const [
                        ButtonSegment(
                          value: BatterySizingMode.automatic,
                          label: Text('Automatic'),
                        ),
                        ButtonSegment(
                          value: BatterySizingMode.manual,
                          label: Text('Manual'),
                        ),
                      ],
                      selected: {project.batterySizingMode},
                      onSelectionChanged: (s) =>
                          provider.setBatterySizingMode(s.first),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            label: 'Unit voltage',
                            field: 'batteryVoltage',
                            suffix: 'V',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NumberField(
                            label: 'Unit capacity',
                            field: 'batteryAh',
                            suffix: 'Ah',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CounterField(
                            label: 'Series (voltage)',
                            value: project.batterySeriesCount,
                            onDecrement: () => provider.updateBatteryBankCount(
                              'batterySeriesCount',
                              -1,
                            ),
                            onIncrement: () => provider.updateBatteryBankCount(
                              'batterySeriesCount',
                              1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CounterField(
                            label: 'Parallel (capacity)',
                            value: project.batteryParallelCount,
                            onDecrement: () => provider.updateBatteryBankCount(
                              'batteryParallelCount',
                              -1,
                            ),
                            onIncrement: () => provider.updateBatteryBankCount(
                              'batteryParallelCount',
                              1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (project.batterySizingMode ==
                            BatterySizingMode.automatic &&
                        battery.recommendedParallelCount > 0 &&
                        battery.recommendedParallelCount !=
                            project.batteryParallelCount) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: provider.applyRecommendedBatteryBank,
                        icon: const Icon(Icons.auto_fix_high, size: 16),
                        label: Text(
                          'Apply recommended: ${battery.recommendedParallelCount} parallel string(s)',
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    const Text(
                      'Series wiring increases bank voltage (Ah stays about the same). '
                      'Parallel wiring increases bank Ah (voltage stays the same).',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!battery.backupEnabled)
                EmptyState(
                  icon: Icons.info_outline,
                  title: 'No backup configured',
                  message:
                      'Choose a backup duration above 0 hours to evaluate this bank.',
                )
              else ...[
                SectionHeader(
                  title: 'Bank Evaluation',
                  icon: Icons.check_circle_outline,
                ),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DesignStatusBadge(status: battery.status),
                        const SizedBox(height: 16),
                        Text(
                          '${battery.bankVoltage.toInt()}V ${battery.bankAh.toStringAsFixed(0)}Ah bank '
                          '(${battery.seriesCount}S${battery.parallelCount}P)',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            MetricTile(
                              label: 'Nominal storage',
                              value: Units.formatWh(battery.nominalBankWh),
                            ),
                            MetricTile(
                              label: 'Usable storage',
                              value: Units.formatWh(battery.usableBankWh),
                            ),
                            MetricTile(
                              label: 'Required (usable)',
                              value: Units.formatWh(battery.requiredUsableWh),
                            ),
                            MetricTile(
                              label: 'Required (nominal)',
                              value: Units.formatWh(battery.requiredNominalWh),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            MetricTile(
                              label: battery.surplusUsableWh >= 0
                                  ? 'Capacity surplus'
                                  : 'Capacity shortfall',
                              value: Units.formatWh(
                                battery.surplusUsableWh.abs(),
                              ),
                              valueColor: battery.surplusUsableWh >= 0
                                  ? null
                                  : Theme.of(context).colorScheme.error,
                            ),
                            MetricTile(
                              label: 'Estimated autonomy',
                              value:
                                  '${battery.estimatedRuntimeHours.toStringAsFixed(1)} h',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Actual runtime depends on battery condition, temperature, discharge '
                          'characteristics, inverter efficiency, load variation and manufacturer '
                          'specifications.',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CalculationExplanation(
                  title: 'Battery Storage',
                  steps: [
                    '${Units.formatWatts(essential.enabledApplianceCount > 0 ? essential.runningLoadW : provider.loadProfile.runningLoadW)} backup load',
                    '× ${battery.backupHours.toStringAsFixed(0)} h backup target',
                    '× ${(1 + project.designReservePercent / 100).toStringAsFixed(2)} reserve factor',
                    '= ${Units.formatWh(battery.requiredUsableWh)} required usable energy',
                  ],
                  result:
                      '÷ ${(project.batteryDoD / 100).toStringAsFixed(2)} DoD ÷ ${(project.batteryEfficiencyPercent / 100).toStringAsFixed(2)} efficiency ≈ ${Units.formatWh(battery.requiredNominalWh)} nominal storage needed',
                ),
              ],
              const SizedBox(height: 20),
              EducationCard(
                title: 'Battery storage basics',
                items: const [
                  InfoExplainer(
                    term: 'Depth of discharge (DoD)',
                    explanation:
                        'The usable percentage of a battery\'s rated capacity. Discharging beyond this shortens battery life.',
                  ),
                  InfoExplainer(
                    term: 'Series vs parallel',
                    explanation:
                        'Series wiring adds battery voltages together (Ah unchanged). Parallel wiring adds battery Ah together (voltage unchanged).',
                  ),
                  InfoExplainer(
                    term: 'Battery bank voltage',
                    explanation:
                        'The combined voltage the bank presents to your inverter/charge controller — must match their supported input.',
                  ),
                  InfoExplainer(
                    term: 'Battery autonomy',
                    explanation:
                        'How long usable battery storage could power a given load in isolation — an estimate, not a guarantee.',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const DisclaimerText(),
            ],
          );
        },
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final String field;
  final String suffix;

  const _NumberField({
    required this.label,
    required this.field,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final value = provider.fieldValue(field, '');
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
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

class _CounterField extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CounterField({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: value > 1 ? onDecrement : null,
              icon: const Icon(Icons.remove, size: 16),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton.filledTonal(
              onPressed: onIncrement,
              icon: const Icon(Icons.add, size: 16),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}
