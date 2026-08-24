import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/units.dart';
import '../../models/surge_mode.dart';
import '../../state/project_provider.dart';
import '../widgets/calculation_explanation.dart';
import '../widgets/disclaimer.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_explainer.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';
import 'projects_screen.dart' show showCreateProjectDialog;

const List<double> _headroomPresets = [10, 20, 25, 30];

/// Inverter Planner: estimates a minimum and planning-class inverter
/// capacity from the project's running load, surge load and headroom.
class InverterScreen extends StatelessWidget {
  const InverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inverter')),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.activeProject;
          if (project == null) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.dns_outlined,
                  title: 'No active project',
                  message: 'Create a project first to plan inverter capacity.',
                  actionLabel: 'New Project',
                  onAction: () => showCreateProjectDialog(context),
                ),
              ),
            );
          }

          final load = provider.loadProfile;
          final inverter = provider.inverterSizing;
          final headroom =
              double.tryParse(
                provider.fieldValue('inverterHeadroomPercent', '20'),
              ) ??
              20;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (load.dailyEnergyWh <= 0)
                EmptyState(
                  icon: Icons.info_outline,
                  title: 'Add appliances first',
                  message:
                      'Inverter sizing is based on your running and surge load from Loads.',
                )
              else ...[
                SectionHeader(
                  title: 'Surge Estimate Mode',
                  icon: Icons.bolt_outlined,
                ),
                SectionCard(
                  title: 'How simultaneous startup is estimated',
                  icon: Icons.bolt,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<SurgeMode>(
                        segments: [
                          ButtonSegment(
                            value: SurgeMode.standard,
                            label: Text(SurgeMode.standard.label),
                          ),
                          ButtonSegment(
                            value: SurgeMode.conservative,
                            label: Text(SurgeMode.conservative.label),
                          ),
                        ],
                        selected: {project.inverterSurgeMode},
                        onSelectionChanged: (s) =>
                            provider.setInverterSurgeMode(s.first),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.inverterSurgeMode.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(title: 'Design Headroom', icon: Icons.tune),
                SectionCard(
                  title: 'Planning margin above running load',
                  icon: Icons.add_road,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final h in _headroomPresets)
                            ChoiceChip(
                              label: Text('${h.toInt()}%'),
                              selected: headroom == h,
                              onSelected: (_) => provider.updateSettingField(
                                'inverterHeadroomPercent',
                                h.toString(),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _NumberField(
                        label: 'Custom headroom',
                        field: 'inverterHeadroomPercent',
                        suffix: '%',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Extra headroom leaves margin for startup surges and future load growth — a '
                        'planning convenience, not a universal engineering requirement.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'Inverter Estimate',
                  icon: Icons.check_circle_outline,
                ),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Planning capacity',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${Units.formatWatts(inverter.recommendedInverterW * 0.9)}–${Units.formatWatts(inverter.recommendedInverterW * 1.1)} class',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const InlineEstimateNote(),
                        const Divider(height: 28),
                        Wrap(
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
                              label: 'Recommended capacity',
                              value: Units.formatWatts(
                                inverter.recommendedInverterW,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CalculationExplanation(
                  title: 'Inverter Capacity',
                  steps: [
                    '${Units.formatWatts(inverter.runningLoadW)} running load',
                    '÷ ${(1 - project.inverterHeadroomPercent / 100).toStringAsFixed(2)} (100% − ${project.inverterHeadroomPercent.toStringAsFixed(0)}% headroom)',
                    '= ${Units.formatWatts(inverter.minInverterW)} minimum',
                  ],
                  result:
                      'Checked against ${Units.formatWatts(inverter.surgeLoadW)} estimated surge → ${Units.formatWatts(inverter.recommendedInverterW)} planning capacity',
                ),
              ],
              const SizedBox(height: 20),
              EducationCard(
                title: 'Inverter sizing basics',
                items: const [
                  InfoExplainer(
                    term: 'Inverter sizing',
                    explanation:
                        'An inverter must comfortably cover your running load and, ideally, a reasonable surge estimate — not just nameplate wattage.',
                  ),
                  InfoExplainer(
                    term: 'Surge power',
                    explanation:
                        'Motor-driven appliances (compressors, pumps, A/C) briefly draw more power at startup than while running.',
                  ),
                  InfoExplainer(
                    term: 'System efficiency',
                    explanation:
                        'Conversion and wiring losses reduce delivered power below an inverter\'s rated capacity — headroom helps absorb this.',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const DisclaimerText(
                text:
                    'Inverter figures are planning estimates only. They do not recommend a specific '
                    'commercial product, and do not claim certification or compatibility with any '
                    'equipment. Verify against manufacturer specifications before purchase or installation.',
              ),
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
