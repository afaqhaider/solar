import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/units.dart';
import '../../models/battery_chemistry.dart';
import '../../models/planning_inputs.dart';
import '../../models/system_recommendation.dart';
import '../../state/project_provider.dart';
import '../widgets/section_card.dart';

/// What-If exploration: edit a scratch copy of the project's planning
/// assumptions and see the effect on solar/battery/inverter sizing, without
/// touching the saved project until the user explicitly applies it.
class WhatIfScreen extends StatefulWidget {
  const WhatIfScreen({super.key});

  @override
  State<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends State<WhatIfScreen> {
  late PlanningInputs _inputs;

  @override
  void initState() {
    super.initState();
    final project = context.read<ProjectProvider>().activeProject;
    _inputs = project?.toPlanningInputs() ?? const PlanningInputs();
  }

  void _reset() {
    final project = context.read<ProjectProvider>().activeProject;
    setState(
      () => _inputs = project?.toPlanningInputs() ?? const PlanningInputs(),
    );
  }

  Future<void> _saveAsScenario() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Scenario'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Scenario name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;
    await context.read<ProjectProvider>().saveScenario(name, _inputs);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scenario saved')));
    }
  }

  Future<void> _applyToProject() async {
    await context.read<ProjectProvider>().applyPlanningInputs(_inputs);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Applied to project')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final current = provider.systemRecommendation;
    final whatIf = provider.buildRecommendation(
      _inputs,
      scenarioName: 'What-If',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('What-If'),
        actions: [
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset to current',
          ),
        ],
      ),
      body: current == null || whatIf == null
          ? const Center(child: Text('No active project'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Text(
                  'Adjust assumptions below to explore alternatives. Nothing is saved until you '
                  'choose to apply it.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Solar assumptions',
                  icon: Icons.wb_sunny,
                  child: Column(
                    children: [
                      _Slider(
                        label: 'Peak sun hours',
                        value: _inputs.peakSunHours,
                        min: 1,
                        max: 8,
                        divisions: 28,
                        suffix: 'h',
                        onChanged: (v) => setState(
                          () => _inputs = _inputs.copyWith(peakSunHours: v),
                        ),
                      ),
                      _Slider(
                        label: 'System efficiency',
                        value: _inputs.systemEfficiencyPercent,
                        min: 40,
                        max: 100,
                        divisions: 60,
                        suffix: '%',
                        onChanged: (v) => setState(
                          () => _inputs = _inputs.copyWith(
                            systemEfficiencyPercent: v,
                          ),
                        ),
                      ),
                      _Slider(
                        label: 'Panel wattage',
                        value: _inputs.panelWattage,
                        min: 100,
                        max: 700,
                        divisions: 60,
                        suffix: 'W',
                        onChanged: (v) => setState(
                          () => _inputs = _inputs.copyWith(panelWattage: v),
                        ),
                      ),
                      _Slider(
                        label: 'Design reserve',
                        value: _inputs.designReservePercent,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        suffix: '%',
                        onChanged: (v) => setState(
                          () => _inputs = _inputs.copyWith(
                            designReservePercent: v,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Battery assumptions',
                  icon: Icons.battery_charging_full,
                  child: Column(
                    children: [
                      DropdownButtonFormField<BatteryChemistry>(
                        initialValue: _inputs.batteryChemistry,
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
                          if (c == null) return;
                          setState(
                            () => _inputs = _inputs.copyWith(
                              batteryChemistry: c,
                              batteryDoD: c.defaultDoDPercent,
                              batteryEfficiencyPercent:
                                  c.defaultEfficiencyPercent,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _Slider(
                        label: 'Backup duration',
                        value: _inputs.backupHours,
                        min: 0,
                        max: 24,
                        divisions: 24,
                        suffix: 'h',
                        onChanged: (v) => setState(
                          () => _inputs = _inputs.copyWith(backupHours: v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionHeader(title: 'Comparison', icon: Icons.compare_arrows),
                _ComparisonTable(current: current, whatIf: whatIf),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveAsScenario,
                        icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                        label: const Text('Save as Scenario'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _applyToProject,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Apply to Project'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Slider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '${clamped.toStringAsFixed(clamped == clamped.roundToDouble() ? 0 : 1)}$suffix',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: clamped,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final SystemRecommendation current;
  final SystemRecommendation whatIf;

  const _ComparisonTable({required this.current, required this.whatIf});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String)>[
      (
        'Recommended array',
        Units.formatWatts(current.solarArraySizing.recommendedArrayW),
        Units.formatWatts(whatIf.solarArraySizing.recommendedArrayW),
      ),
      (
        'Panel count',
        '${current.solarArraySizing.panelCount}',
        '${whatIf.solarArraySizing.panelCount}',
      ),
      (
        'Est. monthly generation',
        Units.formatKwh(current.solarArraySizing.estimatedMonthlyGenerationKWh),
        Units.formatKwh(whatIf.solarArraySizing.estimatedMonthlyGenerationKWh),
      ),
      (
        'Battery usable storage',
        Units.formatWh(current.batterySizing.usableBankWh),
        Units.formatWh(whatIf.batterySizing.usableBankWh),
      ),
      (
        'Battery autonomy',
        '${current.batterySizing.estimatedRuntimeHours.toStringAsFixed(1)} h',
        '${whatIf.batterySizing.estimatedRuntimeHours.toStringAsFixed(1)} h',
      ),
      (
        'Inverter recommendation',
        Units.formatWatts(current.inverterSizing.recommendedInverterW),
        Units.formatWatts(whatIf.inverterSizing.recommendedInverterW),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Metric')),
              DataColumn(label: Text('Current')),
              DataColumn(label: Text('What-If')),
            ],
            rows: [
              for (final r in rows)
                DataRow(
                  cells: [
                    DataCell(Text(r.$1, style: const TextStyle(fontSize: 12))),
                    DataCell(Text(r.$2, style: const TextStyle(fontSize: 12))),
                    DataCell(
                      Text(
                        r.$3,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: r.$2 != r.$3
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
