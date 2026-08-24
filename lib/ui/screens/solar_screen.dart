import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/units.dart';
import '../../state/project_provider.dart';
import '../widgets/calculation_explanation.dart';
import '../widgets/disclaimer.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_explainer.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';
import 'projects_screen.dart' show showCreateProjectDialog;

/// Solar array sizing and panel configuration.
class SolarScreen extends StatelessWidget {
  const SolarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solar Array')),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.activeProject;
          if (project == null) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.wb_sunny_outlined,
                  title: 'No active project',
                  message: 'Create a project first to size a solar array.',
                  actionLabel: 'New Project',
                  onAction: () => showCreateProjectDialog(context),
                ),
              ),
            );
          }

          final array = provider.solarArraySizing;
          final load = provider.loadProfile;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              SectionHeader(title: 'Array Sizing Inputs', icon: Icons.tune),
              SectionCard(
                title: 'Site & panel assumptions',
                icon: Icons.wb_sunny,
                child: Column(
                  children: [
                    _NumberField(
                      label: 'Peak sun hours',
                      field: 'peakSunHours',
                      suffix: 'h/day',
                      helper:
                          'Average daily hours of full-intensity sunlight at your location.',
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      label: 'System efficiency',
                      field: 'systemEfficiencyPercent',
                      suffix: '%',
                      helper:
                          'Accounts for wiring, inverter and soiling losses.',
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      label: 'Design reserve',
                      field: 'designReservePercent',
                      suffix: '%',
                      helper:
                          'Extra margin added on top of the calculated minimum.',
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      label: 'Solar panel wattage',
                      field: 'panelWattage',
                      suffix: 'W',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Panel configuration',
                icon: Icons.grid_view,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            label: 'Panel voltage (Vmp, optional)',
                            field: 'panelVoltage',
                            suffix: 'V',
                            optional: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NumberField(
                            label: 'Panel current (Imp, optional)',
                            field: 'panelCurrentAmps',
                            suffix: 'A',
                            optional: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Series/parallel string configuration must be verified against your '
                        'inverter and charge controller voltage/current limits before wiring.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (load.dailyEnergyWh <= 0)
                EmptyState(
                  icon: Icons.info_outline,
                  title: 'Add appliances first',
                  message:
                      'Solar array sizing is based on your daily energy requirement in Loads.',
                )
              else ...[
                SectionHeader(
                  title: 'Recommended Array',
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
                          'Calculated minimum',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          Units.formatWatts(array.requiredArrayW),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        const Text(
                          'Recommended design value',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          Units.formatWatts(array.recommendedArrayW),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const InlineEstimateNote(),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 24,
                          runSpacing: 12,
                          children: [
                            MetricTile(
                              label: 'Panels needed',
                              value: '${array.panelCount}',
                              sub: '${array.panelWattage.toInt()}W each',
                            ),
                            MetricTile(
                              label: 'Installed capacity',
                              value: Units.formatWatts(
                                array.installedCapacityW,
                              ),
                            ),
                            MetricTile(
                              label: 'Est. daily generation',
                              value: Units.formatWh(
                                array.estimatedDailyGenerationWh,
                              ),
                            ),
                            MetricTile(
                              label: 'Est. monthly generation',
                              value: Units.formatKwh(
                                array.estimatedMonthlyGenerationKWh,
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
                  title: 'Solar Array',
                  steps: [
                    '${Units.formatWh(load.dailyEnergyWh)} daily energy',
                    '÷ ${project.peakSunHours} sun hours',
                    '÷ ${(project.systemEfficiencyPercent / 100).toStringAsFixed(2)} efficiency',
                    '= ${Units.formatWatts(array.requiredArrayW)} minimum',
                  ],
                  result:
                      'With ${project.designReservePercent.toStringAsFixed(0)}% reserve ≈ ${Units.formatWatts(array.recommendedArrayW)} planning requirement',
                ),
              ],
              const SizedBox(height: 20),
              EducationCard(
                title: 'How solar array sizing works',
                items: const [
                  InfoExplainer(
                    term: 'Peak sun hours',
                    explanation:
                        'Not daylight hours — the equivalent hours of maximum sunlight intensity your location receives per day.',
                  ),
                  InfoExplainer(
                    term: 'System losses',
                    explanation:
                        'Wiring resistance, inverter conversion and panel soiling reduce usable output below nameplate rating.',
                  ),
                  InfoExplainer(
                    term: 'Calculated minimum vs recommended',
                    explanation:
                        'The minimum meets today\'s measured load exactly. The recommended value adds a reserve for cloudy days and future load growth.',
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
  final String? helper;
  final bool optional;

  const _NumberField({
    required this.label,
    required this.field,
    required this.suffix,
    this.helper,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final value = provider.fieldValue(field, '');
    return TextField(
      decoration: InputDecoration(
        labelText: optional ? '$label (optional)' : label,
        suffixText: suffix,
        helperText: helper,
        helperMaxLines: 2,
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
