import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/units.dart';
import '../../state/project_provider.dart';
import '../../state/tab_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';
import 'projects_screen.dart' show showCreateProjectDialog;
import 'settings_screen.dart';

/// Solar project overview and quick actions — the app's home screen.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solar Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Solar System Planner',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
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
                  icon: Icons.solar_power_outlined,
                  title: 'Plan Your First Solar System',
                  message:
                      '1. Create a project\n'
                      '2. Add your loads\n'
                      '3. Configure solar assumptions\n'
                      '4. Review the recommended system',
                  actionLabel: 'Create Solar Project',
                  onAction: () => showCreateProjectDialog(context),
                ),
              ),
            );
          }

          final load = provider.loadProfile;
          final array = provider.solarArraySizing;
          final inverter = provider.inverterSizing;
          final battery = provider.batterySizing;
          final balance = provider.energyBalance;
          final completeness = provider.completeness;
          final tabs = context.read<SolarTabController>();

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        project.systemType.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  load.totalApplianceCount == 0
                      ? 'No appliances added yet.'
                      : '${load.enabledApplianceCount} of ${load.totalApplianceCount} appliances active',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                if (completeness.isNotEmpty)
                  SectionCard(
                    title: 'Project Completeness',
                    icon: Icons.checklist,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in completeness.entries)
                          Chip(
                            avatar: Icon(
                              entry.value
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 14,
                              color: entry.value ? Colors.green : Colors.grey,
                            ),
                            label: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 700 ? 3 : 2;
                    final cards = [
                      DashboardStatCard(
                        label: 'Energy usage',
                        value: Units.formatKwh(load.monthlyEnergyKWh),
                        sub: '${Units.formatWh(load.dailyEnergyWh)}/day',
                        icon: Icons.bolt,
                        onTap: () => tabs.goTo(SolarTabController.loads),
                      ),
                      DashboardStatCard(
                        label: 'Solar array',
                        value: Units.formatWatts(array.recommendedArrayW),
                        sub: '${array.panelCount} panels recommended',
                        icon: Icons.wb_sunny,
                        onTap: () => tabs.goTo(SolarTabController.solar),
                      ),
                      DashboardStatCard(
                        label: 'Battery',
                        value: battery.backupEnabled
                            ? Units.formatWh(battery.usableBankWh)
                            : 'Not configured',
                        sub: battery.backupEnabled ? 'usable storage' : null,
                        icon: Icons.battery_charging_full,
                        onTap: () => tabs.goTo(SolarTabController.battery),
                      ),
                      DashboardStatCard(
                        label: 'Inverter',
                        value: Units.formatWatts(inverter.recommendedInverterW),
                        sub: 'planning class',
                        icon: Icons.dns,
                        onTap: () => tabs.goTo(SolarTabController.inverter),
                      ),
                      DashboardStatCard(
                        label: 'Energy balance',
                        value:
                            '${balance.coveragePercent.clamp(0, 999).toStringAsFixed(0)}%',
                        sub: 'of consumption covered',
                        icon: Icons.balance,
                        onTap: () => tabs.goTo(SolarTabController.system),
                      ),
                      DashboardStatCard(
                        label: 'System type',
                        value: project.systemType.label,
                        sub: project.systemType.batteryRequired
                            ? 'battery required'
                            : 'battery optional',
                        icon: Icons.hub_outlined,
                        onTap: () => tabs.goTo(SolarTabController.system),
                      ),
                    ];
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: cards,
                    );
                  },
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Quick Actions',
                  icon: Icons.flash_on,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickAction(
                        label: 'Add Appliance',
                        icon: Icons.add_circle_outline,
                        onTap: () => tabs.goTo(SolarTabController.loads),
                      ),
                      _QuickAction(
                        label: 'Size Solar Array',
                        icon: Icons.wb_sunny_outlined,
                        onTap: () => tabs.goTo(SolarTabController.solar),
                      ),
                      _QuickAction(
                        label: 'Configure Battery',
                        icon: Icons.battery_charging_full_outlined,
                        onTap: () => tabs.goTo(SolarTabController.battery),
                      ),
                      _QuickAction(
                        label: 'Estimate Inverter',
                        icon: Icons.dns_outlined,
                        onTap: () => tabs.goTo(SolarTabController.inverter),
                      ),
                      _QuickAction(
                        label: 'View System Recommendation',
                        icon: Icons.dns_outlined,
                        onTap: () => tabs.goTo(SolarTabController.system),
                      ),
                      _QuickAction(
                        label: 'New Project',
                        icon: Icons.folder_outlined,
                        onTap: () => showCreateProjectDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
