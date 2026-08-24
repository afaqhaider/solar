import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';

class _AssumptionRow {
  final String label;
  final String field;
  final String suffix;
  final String affects;
  const _AssumptionRow(this.label, this.field, this.suffix, this.affects);
}

const _rows = [
  _AssumptionRow(
    'Peak sun hours',
    'peakSunHours',
    'h/day',
    'Solar array sizing, generation estimate, energy balance',
  ),
  _AssumptionRow(
    'System efficiency',
    'systemEfficiencyPercent',
    '%',
    'Solar array sizing, generation estimate',
  ),
  _AssumptionRow(
    'Solar design reserve',
    'designReservePercent',
    '%',
    'Recommended array size, required battery storage',
  ),
  _AssumptionRow(
    'Battery DoD',
    'batteryDoD',
    '%',
    'Usable battery storage, required nominal storage',
  ),
  _AssumptionRow(
    'Battery efficiency',
    'batteryEfficiencyPercent',
    '%',
    'Usable battery storage, required nominal storage',
  ),
  _AssumptionRow(
    'Backup target',
    'backupHours',
    'h',
    'Required battery storage, estimated autonomy',
  ),
  _AssumptionRow(
    'Inverter headroom',
    'inverterHeadroomPercent',
    '%',
    'Minimum and planning inverter capacity',
  ),
  _AssumptionRow(
    'Electricity price',
    'pricePerKWh',
    '/kWh',
    'Estimated savings and simple payback',
  ),
  _AssumptionRow(
    'Fixed monthly charge',
    'fixedChargePerMonth',
    '',
    'Estimated current monthly cost',
  ),
];

/// Centralizes every assumption that feeds a calculation, in one place,
/// with a note on what each one affects.
class AssumptionsScreen extends StatelessWidget {
  const AssumptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assumptions')),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.activeProject;
          if (project == null) {
            return Center(
              child: EmptyState(
                icon: Icons.tune,
                title: 'No active project',
                message:
                    'Open a project to review and adjust its planning assumptions.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      controller:
                          TextEditingController(text: project.currencyLabel)
                            ..selection = TextSelection.collapsed(
                              offset: project.currencyLabel.length,
                            ),
                      onChanged: provider.updateCurrencyLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final row in _rows) ...[
                SectionCard(
                  title: row.label,
                  icon: Icons.tune,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AssumptionField(field: row.field, suffix: row.suffix),
                      const SizedBox(height: 6),
                      Text(
                        'Affects: ${row.affects}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              const Text(
                'User-entered values are used as given. Values you have not changed are example planning '
                'defaults, not official engineering standards.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AssumptionField extends StatelessWidget {
  final String field;
  final String suffix;
  const _AssumptionField({required this.field, required this.suffix});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final value = provider.fieldValue(field, '');
    return TextField(
      decoration: InputDecoration(
        suffixText: suffix,
        errorText: provider.fieldErrors[field],
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      onChanged: (v) => provider.updateSettingField(field, v),
    );
  }
}
