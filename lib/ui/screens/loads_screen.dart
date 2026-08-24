import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/units.dart';
import '../../models/appliance.dart';
import '../../state/project_provider.dart';
import '../widgets/appliance_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_explainer.dart';
import '../widgets/load_breakdown_chart.dart';
import '../widgets/section_card.dart';
import 'projects_screen.dart' show showCreateProjectDialog;

/// Load Planner: add/edit/duplicate/delete/enable appliances, and see the
/// resulting load profile summary and breakdown.
class LoadsScreen extends StatelessWidget {
  const LoadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loads')),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.activeProject;
          if (project == null) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.electrical_services_outlined,
                  title: 'No active project',
                  message: 'Create a project first to start adding appliances.',
                  actionLabel: 'New Project',
                  onAction: () => showCreateProjectDialog(context),
                ),
              ),
            );
          }

          final load = provider.loadProfile;
          final essential = provider.essentialLoadProfile;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  SectionHeader(title: 'Load Summary', icon: Icons.summarize),
                  SectionCard(
                    title: 'Load profile',
                    icon: Icons.speed,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 480;
                        final metrics = [
                          _metric(
                            'Connected load',
                            Units.formatWatts(load.connectedLoadW),
                          ),
                          _metric(
                            'Running load',
                            Units.formatWatts(load.runningLoadW),
                          ),
                          _metric(
                            'Peak / surge load',
                            Units.formatWatts(load.peakLoadW),
                          ),
                          _metric(
                            'Daily consumption',
                            Units.formatWh(load.dailyEnergyWh),
                          ),
                          _metric(
                            'Monthly consumption',
                            Units.formatKwh(load.monthlyEnergyKWh),
                          ),
                        ];
                        return Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: [
                            for (final m in metrics)
                              SizedBox(
                                width: wide ? 140 : double.infinity,
                                child: m,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Where your energy goes',
                    icon: Icons.pie_chart_outline,
                    child: LoadBreakdownChart(breakdown: load.breakdown),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Essential load profile',
                    icon: Icons.shield_outlined,
                    child: essential.enabledApplianceCount == 0
                        ? const Text(
                            'No appliances marked "Backup required" yet. Mark essentials like a '
                            'fridge, lights or router below so battery and inverter sizing can '
                            'target just what needs to stay on during an outage.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 480;
                              final metrics = [
                                _metric(
                                  'Total connected load',
                                  Units.formatWatts(load.connectedLoadW),
                                ),
                                _metric(
                                  'Essential backup load',
                                  Units.formatWatts(essential.runningLoadW),
                                ),
                                _metric(
                                  'Daily total energy',
                                  Units.formatWh(load.dailyEnergyWh),
                                ),
                                _metric(
                                  'Essential daily energy',
                                  Units.formatWh(essential.dailyEnergyWh),
                                ),
                              ];
                              return Wrap(
                                spacing: 24,
                                runSpacing: 16,
                                children: [
                                  for (final m in metrics)
                                    SizedBox(
                                      width: wide ? 160 : double.infinity,
                                      child: m,
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(title: 'Appliances', icon: Icons.list_alt),
                  if (project.appliances.isEmpty)
                    EmptyState(
                      icon: Icons.add_circle_outline,
                      title: 'No appliances added',
                      message: 'Add appliances to build your load profile.',
                      actionLabel: 'Add Appliance',
                      onAction: () => _showApplianceDialog(context),
                    )
                  else
                    ...project.appliances.map(
                      (a) => _ApplianceTile(appliance: a),
                    ),
                  const SizedBox(height: 20),
                  EducationCard(
                    title: 'Watts vs watt-hours',
                    items: const [
                      InfoExplainer(
                        term: 'Watt (W)',
                        explanation:
                            'The instantaneous rate an appliance draws power while running.',
                      ),
                      InfoExplainer(
                        term: 'Watt-hour (Wh)',
                        explanation:
                            'Energy used over time: watts × hours. This is what your solar system has to replace each day.',
                      ),
                      InfoExplainer(
                        term: 'Peak / surge load',
                        explanation:
                            'Some motors briefly draw far more power at startup than while running — this affects inverter sizing, not daily energy use.',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          if (provider.activeProject == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showApplianceDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Appliance'),
          );
        },
      ),
    );
  }

  static Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  static void _showApplianceDialog(
    BuildContext context, {
    Appliance? appliance,
  }) {
    showDialog(
      context: context,
      builder: (context) => ApplianceDialog(appliance: appliance),
    );
  }
}

class _ApplianceTile extends StatelessWidget {
  final Appliance appliance;
  const _ApplianceTile({required this.appliance});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProjectProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            Checkbox(
              value: appliance.enabled,
              onChanged: (_) => provider.toggleApplianceEnabled(appliance.id),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          appliance.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: appliance.enabled ? null : Colors.grey,
                            decoration: appliance.enabled
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (appliance.backupRequired) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.shield,
                          size: 13,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${appliance.wattage.toInt()}W x ${appliance.quantity} · ${appliance.usageHours}h/day · ${appliance.daysPerWeek.toInt()}d/wk',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              Units.formatWh(appliance.averageDailyWh),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    showDialog(
                      context: context,
                      builder: (context) =>
                          ApplianceDialog(appliance: appliance),
                    );
                    break;
                  case 'duplicate':
                    provider.duplicateAppliance(appliance.id);
                    break;
                  case 'backup':
                    provider.toggleApplianceBackupRequired(appliance.id);
                    break;
                  case 'delete':
                    provider.deleteAppliance(appliance.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Text('Duplicate'),
                ),
                PopupMenuItem(
                  value: 'backup',
                  child: Text(
                    appliance.backupRequired
                        ? 'Remove from backup'
                        : 'Mark backup required',
                  ),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
