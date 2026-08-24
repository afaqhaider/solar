import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/project_provider.dart';
import '../state/tab_controller.dart';
import 'screens/battery_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inverter_screen.dart';
import 'screens/loads_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/solar_screen.dart';
import 'screens/system_screen.dart';

/// Adaptive navigation shell: bottom navigation on phones, a sidebar
/// (NavigationRail) on tablets/wide layouts. This is the app's primary
/// solar-planning workflow — Dashboard, Loads, Solar, Battery, Inverter,
/// System, Projects — replacing the old single-screen calculator layout.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static const double tabletBreakpoint = 840;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _destinations = [
    _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _NavItem(
      'Loads',
      Icons.electrical_services_outlined,
      Icons.electrical_services,
    ),
    _NavItem('Solar', Icons.wb_sunny_outlined, Icons.wb_sunny),
    _NavItem(
      'Battery',
      Icons.battery_charging_full_outlined,
      Icons.battery_charging_full,
    ),
    _NavItem('Inverter', Icons.dns_outlined, Icons.dns),
    _NavItem('System', Icons.fact_check_outlined, Icons.fact_check),
    _NavItem('Projects', Icons.folder_outlined, Icons.folder),
  ];

  static const _screens = [
    DashboardScreen(),
    LoadsScreen(),
    SolarScreen(),
    BatteryScreen(),
    InverterScreen(),
    SystemScreen(),
    ProjectsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectProvider, SolarTabController>(
      builder: (context, provider, tabs, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppShell.tabletBreakpoint;
            if (isWide) return _buildWideLayout(context, tabs);
            return _buildCompactLayout(context, tabs);
          },
        );
      },
    );
  }

  Widget _buildCompactLayout(BuildContext context, SolarTabController tabs) {
    return Scaffold(
      body: IndexedStack(index: tabs.index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.index,
        onDestinationSelected: tabs.goTo,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, SolarTabController tabs) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // A NavigationRail with labelType.all needs roughly 72px per
          // destination plus the leading logo. On a short/landscape window
          // there isn't room for that, so drop to icons-only with a scrollable
          // fallback rather than overflowing.
          const perDestination = 72.0;
          const leadingHeight = 64.0;
          final neededForLabels =
              leadingHeight + perDestination * _destinations.length;
          final fitsLabels = constraints.maxHeight >= neededForLabels;

          Widget rail = NavigationRail(
            selectedIndex: tabs.index,
            onDestinationSelected: tabs.goTo,
            labelType: fitsLabels
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.none,
            leading: fitsLabels
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Icon(Icons.solar_power, size: 32),
                  )
                : null,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          );

          if (!fitsLabels) {
            // Still doesn't fit icons-only (extremely short window) — let it
            // scroll instead of overflowing.
            final neededForIcons = perDestination * 0.7 * _destinations.length;
            if (constraints.maxHeight < neededForIcons) {
              rail = SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(child: rail),
                ),
              );
            }
          }

          return Row(
            children: [
              rail,
              const VerticalDivider(width: 1),
              Expanded(
                child: IndexedStack(index: tabs.index, children: _screens),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavItem(this.label, this.icon, this.selectedIcon);
}
