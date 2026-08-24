import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/units.dart';
import '../../models/planning_inputs.dart';
import '../../models/scenario.dart';
import '../../models/system_recommendation.dart';
import '../../state/project_provider.dart';
import '../widgets/empty_state.dart';

/// Lists saved scenarios for the active project and compares two of them
/// (or a scenario against the live project) side by side.
class ScenariosScreen extends StatefulWidget {
  const ScenariosScreen({super.key});

  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  String? _leftId; // null = current project
  String? _rightId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.activeProject;

    return Scaffold(
      appBar: AppBar(title: const Text('Scenarios')),
      body: project == null
          ? const Center(child: Text('No active project'))
          : project.scenarios.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.bookmark_border,
                  title: 'No saved scenarios',
                  message:
                      'Save a scenario from What-If to compare configurations here.',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ScenarioPicker(
                        label: 'Compare',
                        scenarios: project.scenarios,
                        selectedId: _leftId,
                        onChanged: (id) => setState(() => _leftId = id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ScenarioPicker(
                        label: 'Against',
                        scenarios: project.scenarios,
                        selectedId: _rightId,
                        onChanged: (id) => setState(() => _rightId = id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildComparison(context, provider, project.scenarios),
                const SizedBox(height: 20),
                const Text(
                  'Saved scenarios',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                for (final s in project.scenarios)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.bookmark_outline),
                      title: Text(s.name),
                      subtitle: Text(
                        'Saved ${_formatDate(s.createdAt)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _confirmApply(context, provider, s),
                            child: const Text('Apply'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => provider.deleteScenario(s.id),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildComparison(
    BuildContext context,
    ProjectProvider provider,
    List<ProjectScenario> scenarios,
  ) {
    final leftInputs = _resolveInputs(provider, scenarios, _leftId);
    final rightInputs = _resolveInputs(provider, scenarios, _rightId);
    if (leftInputs == null || rightInputs == null) {
      return const Text(
        'Pick two configurations to compare.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
    final left = provider.buildRecommendation(
      leftInputs,
      scenarioName: _labelFor(scenarios, _leftId),
    );
    final right = provider.buildRecommendation(
      rightInputs,
      scenarioName: _labelFor(scenarios, _rightId),
    );
    if (left == null || right == null) return const SizedBox.shrink();
    return _ScenarioComparisonTable(a: left, b: right);
  }

  PlanningInputs? _resolveInputs(
    ProjectProvider provider,
    List<ProjectScenario> scenarios,
    String? id,
  ) {
    if (id == null) return provider.activeProject?.toPlanningInputs();
    for (final s in scenarios) {
      if (s.id == id) return s.inputs;
    }
    return null;
  }

  String _labelFor(List<ProjectScenario> scenarios, String? id) {
    if (id == null) return 'Current';
    for (final s in scenarios) {
      if (s.id == id) return s.name;
    }
    return 'Scenario';
  }

  Future<void> _confirmApply(
    BuildContext context,
    ProjectProvider provider,
    ProjectScenario scenario,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Scenario?'),
        content: Text(
          'This replaces the current project\'s solar, battery and inverter assumptions with those from '
          '"${scenario.name}". This can be changed again afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.applyPlanningInputs(
        scenario.inputs,
        activityMessage: 'Scenario "${scenario.name}" applied',
      );
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _ScenarioPicker extends StatelessWidget {
  final String label;
  final List<ProjectScenario> scenarios;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _ScenarioPicker({
    required this.label,
    required this.scenarios,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: selectedId,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Current project'),
        ),
        for (final s in scenarios)
          DropdownMenuItem<String?>(value: s.id, child: Text(s.name)),
      ],
      onChanged: onChanged,
    );
  }
}

class _ScenarioComparisonTable extends StatelessWidget {
  final SystemRecommendation a;
  final SystemRecommendation b;

  const _ScenarioComparisonTable({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String)>[
      (
        'Array size',
        Units.formatWatts(a.solarArraySizing.recommendedArrayW),
        Units.formatWatts(b.solarArraySizing.recommendedArrayW),
      ),
      (
        'Est. generation',
        Units.formatKwh(a.solarArraySizing.estimatedMonthlyGenerationKWh),
        Units.formatKwh(b.solarArraySizing.estimatedMonthlyGenerationKWh),
      ),
      (
        'Panel quantity',
        '${a.solarArraySizing.panelCount}',
        '${b.solarArraySizing.panelCount}',
      ),
      (
        'Battery storage',
        Units.formatWh(a.batterySizing.usableBankWh),
        Units.formatWh(b.batterySizing.usableBankWh),
      ),
      (
        'Backup duration',
        '${a.batterySizing.backupHours.toStringAsFixed(0)} h',
        '${b.batterySizing.backupHours.toStringAsFixed(0)} h',
      ),
      (
        'Inverter sizing',
        Units.formatWatts(a.inverterSizing.recommendedInverterW),
        Units.formatWatts(b.inverterSizing.recommendedInverterW),
      ),
      (
        'Design reserve',
        '${a.assumptions.designReservePercent.toStringAsFixed(0)}%',
        '${b.assumptions.designReservePercent.toStringAsFixed(0)}%',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            columns: [
              const DataColumn(label: Text('Metric')),
              DataColumn(label: Text(a.scenarioName ?? 'A')),
              DataColumn(label: Text(b.scenarioName ?? 'B')),
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
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
