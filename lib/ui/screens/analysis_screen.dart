import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/units.dart';
import '../../state/project_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/load_breakdown_chart.dart';
import '../widgets/section_card.dart';

/// Advanced Energy Analysis: consumption/generation over multiple
/// timeframes, coverage, battery autonomy, and where the load actually
/// comes from (by appliance and by category) — the "why" behind the sizing.
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.activeProject;
          if (project == null) {
            return Center(
              child: EmptyState(
                icon: Icons.analytics_outlined,
                title: 'No active project',
                message:
                    'Open a project to see detailed consumption and generation analysis.',
              ),
            );
          }
          final load = provider.loadProfile;
          if (load.dailyEnergyWh <= 0) {
            return Center(
              child: EmptyState(
                icon: Icons.info_outline,
                title: 'No load data yet',
                message:
                    'Add appliances in Loads to unlock consumption and generation analysis.',
              ),
            );
          }

          final array = provider.solarArraySizing;
          final battery = provider.batterySizing;
          final balance = provider.energyBalance;
          final essential = provider.essentialLoadProfile;

          final annualConsumptionKWh = load.monthlyEnergyKWh * 12;
          final annualGenerationKWh = array.estimatedMonthlyGenerationKWh * 12;

          // Category-level breakdown from optional appliance categories.
          final categoryTotals = <String, double>{};
          for (final a in project.appliances.where((a) => a.enabled)) {
            categoryTotals[a.category] =
                (categoryTotals[a.category] ?? 0) + a.averageDailyWh;
          }
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionHeader(
                title: 'Consumption Analysis',
                icon: Icons.show_chart,
              ),
              SectionCard(
                title: 'Energy consumption over time',
                icon: Icons.calendar_view_month,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _stat('Daily', Units.formatWh(load.dailyEnergyWh)),
                    _stat('Monthly', Units.formatKwh(load.monthlyEnergyKWh)),
                    _stat('Annualized', Units.formatKwh(annualConsumptionKWh)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: 'Solar Generation',
                icon: Icons.wb_sunny_outlined,
              ),
              SectionCard(
                title: 'Estimated generation over time',
                icon: Icons.calendar_view_month,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _stat(
                      'Daily',
                      Units.formatWh(array.estimatedDailyGenerationWh),
                    ),
                    _stat(
                      'Monthly',
                      Units.formatKwh(array.estimatedMonthlyGenerationKWh),
                    ),
                    _stat('Annualized', Units.formatKwh(annualGenerationKWh)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: 'Energy Coverage & Balance',
                icon: Icons.balance,
              ),
              SectionCard(
                title: 'Coverage of consumption',
                icon: Icons.pie_chart_outline,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _stat(
                      'Coverage',
                      '${balance.coveragePercent.clamp(0, 999).toStringAsFixed(0)}%',
                    ),
                    _stat(
                      balance.surplusWh >= 0
                          ? 'Estimated surplus'
                          : 'Estimated shortfall',
                      Units.formatWh(balance.surplusWh.abs()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: 'Battery',
                icon: Icons.battery_charging_full_outlined,
              ),
              SectionCard(
                title: 'Storage & autonomy',
                icon: Icons.battery_std,
                child: !battery.backupEnabled
                    ? const Text(
                        'Not configured — set a backup duration in Battery.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _stat(
                            'Required storage',
                            Units.formatWh(battery.requiredUsableWh),
                          ),
                          _stat(
                            'Configured storage',
                            Units.formatWh(battery.usableBankWh),
                          ),
                          _stat(
                            'Estimated autonomy',
                            '${battery.estimatedRuntimeHours.toStringAsFixed(1)} h',
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              SectionHeader(title: 'Load Analysis', icon: Icons.list_alt),
              SectionCard(
                title: 'Highest-consuming appliances',
                icon: Icons.trending_up,
                child: LoadBreakdownChart(
                  breakdown: load.breakdown,
                  maxItems: 8,
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                title: 'Essential vs. non-essential consumption',
                icon: Icons.shield_outlined,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _stat('Essential', Units.formatWh(essential.dailyEnergyWh)),
                    _stat(
                      'Non-essential',
                      Units.formatWh(
                        load.dailyEnergyWh - essential.dailyEnergyWh,
                      ),
                    ),
                  ],
                ),
              ),
              if (sortedCategories.length > 1) ...[
                const SizedBox(height: 10),
                SectionCard(
                  title: 'Consumption by category',
                  icon: Icons.category_outlined,
                  child: Column(
                    children: [
                      for (final entry in sortedCategories)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                '${(entry.value / load.dailyEnergyWh * 100).toStringAsFixed(0)}% · ${Units.formatWh(entry.value)}/day',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Figures shown are calculated planning estimates rounded for readability — not '
                'measured field data.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value) => SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
