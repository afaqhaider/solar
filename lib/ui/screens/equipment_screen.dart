import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/compatibility_result.dart';
import '../../models/equipment_specs.dart';
import '../../models/project.dart';
import '../../models/string_planning_result.dart';
import '../../services/equipment_compatibility_service.dart';
import '../../services/string_planning_service.dart';
import '../../state/equipment_library_provider.dart';
import '../../state/project_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';
import 'equipment_library_screen.dart';

const _compatibilityService = EquipmentCompatibilityService();
const _stringService = StringPlanningService();

/// Equipment Workspace: the panel/battery/inverter specs a user is
/// considering for this project (not an online marketplace), mathematical
/// compatibility checks, and a basic PV string planner.
class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'My Equipment library',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EquipmentLibraryScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.activeProject;
          if (project == null) {
            return Center(
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No active project',
                message:
                    'Create a project first to define the equipment you are considering.',
              ),
            );
          }

          final panel = project.selectedPanel ?? const PanelSpec();
          final battery =
              project.selectedBattery ?? const BatteryEquipmentSpec();
          final inverter = project.selectedInverter ?? const InverterSpec();

          final panelChecks = (!panel.isEmpty || !inverter.isEmpty)
              ? _compatibilityService.checkPanelsAgainstInverter(
                  panel,
                  inverter,
                )
              : const <CompatibilityCheck>[];
          final batteryCheck = _compatibilityService
              .checkBatteryAgainstInverter(battery, inverter);

          final stringResult = !panel.isEmpty
              ? _stringService.computeStringPlan(
                  panel: panel,
                  panelsPerString: project.stringPanelsPerString,
                  parallelStrings: project.stringParallelStrings,
                )
              : StringPlanningResult.empty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              SectionHeader(title: 'Solar Panel', icon: Icons.grid_view),
              _PanelForm(panel: panel),
              const SizedBox(height: 16),
              SectionHeader(title: 'Battery', icon: Icons.battery_std),
              _BatteryForm(battery: battery),
              const SizedBox(height: 16),
              SectionHeader(title: 'Inverter', icon: Icons.dns),
              _InverterForm(inverter: inverter),
              const SizedBox(height: 20),
              SectionHeader(title: 'Compatibility', icon: Icons.rule),
              SectionCard(
                title: 'Panels vs. inverter',
                icon: Icons.compare_arrows,
                child: panelChecks.isEmpty
                    ? const Text(
                        'Enter panel and inverter specifications to check compatibility.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : Column(
                        children: [
                          for (final c in panelChecks)
                            _CompatibilityRow(check: c),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                title: 'Battery vs. inverter',
                icon: Icons.compare_arrows,
                child: _CompatibilityRow(check: batteryCheck),
              ),
              const SizedBox(height: 8),
              const Text(
                compatibilityDisclaimer,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SectionHeader(title: 'PV String Planner', icon: Icons.cable),
              SectionCard(
                title: 'String layout',
                icon: Icons.cable,
                child: panel.isEmpty
                    ? const Text(
                        'Enter panel specifications above to plan strings.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : _StringPlannerForm(
                        project: project,
                        result: stringResult,
                        inverter: inverter,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompatibilityRow extends StatelessWidget {
  final CompatibilityCheck check;
  const _CompatibilityRow({required this.check});

  @override
  Widget build(BuildContext context) {
    final color = switch (check.status) {
      CompatibilityStatus.withinEnteredLimits => Colors.green.shade700,
      CompatibilityStatus.outsideEnteredLimits => Colors.orange.shade800,
      CompatibilityStatus.insufficientData => Colors.grey.shade600,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            switch (check.status) {
              CompatibilityStatus.withinEnteredLimits =>
                Icons.check_circle_outline,
              CompatibilityStatus.outsideEnteredLimits =>
                Icons.warning_amber_rounded,
              CompatibilityStatus.insufficientData => Icons.help_outline,
            },
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  check.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  check.detail,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelForm extends StatelessWidget {
  final PanelSpec panel;
  const _PanelForm({required this.panel});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProjectProvider>();
    return SectionCard(
      title: 'Panel specification (optional fields)',
      icon: Icons.grid_view,
      trailing: TextButton(
        onPressed: () => _pickFromLibrary(context),
        child: const Text('From Library'),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _text(
                  'Manufacturer',
                  panel.manufacturer,
                  (v) => provider.setSelectedPanel(
                    panel.copyWith(manufacturer: v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _text(
                  'Model',
                  panel.model,
                  (v) => provider.setSelectedPanel(panel.copyWith(model: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _num(
                  'Rated power (W)',
                  panel.ratedPowerW,
                  (v) => provider.setSelectedPanel(
                    panel.copyWith(ratedPowerW: v ?? 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _num(
                  'Quantity',
                  panel.quantity.toDouble(),
                  (v) => provider.setSelectedPanel(
                    panel.copyWith(quantity: (v ?? 1).round()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _num(
                  'Voc (V)',
                  panel.voc,
                  (v) => provider.setSelectedPanel(
                    panel.copyWith(voc: v, clearVoc: v == null),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _num(
                  'Vmp (V)',
                  panel.vmp,
                  (v) => provider.setSelectedPanel(
                    panel.copyWith(vmp: v, clearVmp: v == null),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _num(
                  'Isc (A)',
                  panel.isc,
                  (v) => provider.setSelectedPanel(
                    panel.copyWith(isc: v, clearIsc: v == null),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _num(
                  'Imp (A)',
                  panel.imp,
                  (v) => provider.setSelectedPanel(
                    panel.copyWith(imp: v, clearImp: v == null),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromLibrary(BuildContext context) async {
    final library = context.read<EquipmentLibraryProvider>();
    final provider = context.read<ProjectProvider>();
    final selected = await showDialog<PanelSpec>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select a panel'),
        children: [
          if (library.panels.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No saved panels yet.'),
            ),
          for (final item in library.panels)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item.spec),
              child: Text(
                '${item.name} — ${item.spec.ratedPowerW.toStringAsFixed(0)}W',
              ),
            ),
        ],
      ),
    );
    if (selected != null) await provider.setSelectedPanel(selected);
  }
}

class _BatteryForm extends StatelessWidget {
  final BatteryEquipmentSpec battery;
  const _BatteryForm({required this.battery});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProjectProvider>();
    return SectionCard(
      title: 'Battery specification (optional fields)',
      icon: Icons.battery_std,
      trailing: TextButton(
        onPressed: () => _pickFromLibrary(context),
        child: const Text('From Library'),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _text(
                  'Manufacturer',
                  battery.manufacturer,
                  (v) => provider.setSelectedBattery(
                    battery.copyWith(manufacturer: v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _text(
                  'Model',
                  battery.model,
                  (v) =>
                      provider.setSelectedBattery(battery.copyWith(model: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _num(
                  'Nominal voltage (V)',
                  battery.nominalVoltage,
                  (v) => provider.setSelectedBattery(
                    battery.copyWith(nominalVoltage: v ?? 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _num(
                  'Capacity (Ah)',
                  battery.capacityAh,
                  (v) => provider.setSelectedBattery(
                    battery.copyWith(capacityAh: v ?? 0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _num(
                  'Series',
                  battery.seriesCount.toDouble(),
                  (v) => provider.setSelectedBattery(
                    battery.copyWith(seriesCount: (v ?? 1).round()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _num(
                  'Parallel',
                  battery.parallelCount.toDouble(),
                  (v) => provider.setSelectedBattery(
                    battery.copyWith(parallelCount: (v ?? 1).round()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromLibrary(BuildContext context) async {
    final library = context.read<EquipmentLibraryProvider>();
    final provider = context.read<ProjectProvider>();
    final selected = await showDialog<BatteryEquipmentSpec>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select a battery'),
        children: [
          if (library.batteries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No saved batteries yet.'),
            ),
          for (final item in library.batteries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item.spec),
              child: Text(
                '${item.name} — ${item.spec.nominalVoltage.toStringAsFixed(0)}V ${item.spec.capacityAh.toStringAsFixed(0)}Ah',
              ),
            ),
        ],
      ),
    );
    if (selected != null) await provider.setSelectedBattery(selected);
  }
}

class _InverterForm extends StatelessWidget {
  final InverterSpec inverter;
  const _InverterForm({required this.inverter});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProjectProvider>();
    return SectionCard(
      title: 'Inverter specification (optional fields)',
      icon: Icons.dns,
      trailing: TextButton(
        onPressed: () => _pickFromLibrary(context),
        child: const Text('From Library'),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _text(
                  'Manufacturer',
                  inverter.manufacturer,
                  (v) => provider.setSelectedInverter(
                    inverter.copyWith(manufacturer: v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _text(
                  'Model',
                  inverter.model,
                  (v) =>
                      provider.setSelectedInverter(inverter.copyWith(model: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _num(
                  'Rated output (W)',
                  inverter.ratedOutputW,
                  (v) => provider.setSelectedInverter(
                    inverter.copyWith(ratedOutputW: v ?? 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _num(
                  'Max PV input (W)',
                  inverter.maxPvInputW,
                  (v) => provider.setSelectedInverter(
                    inverter.copyWith(
                      maxPvInputW: v,
                      clearMaxPvInput: v == null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _num(
                  'DC input voltage (V)',
                  inverter.dcInputVoltage,
                  (v) => provider.setSelectedInverter(
                    inverter.copyWith(
                      dcInputVoltage: v,
                      clearDcInput: v == null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _num(
                  'Max PV voltage (V)',
                  inverter.maxPvVoltage,
                  (v) => provider.setSelectedInverter(
                    inverter.copyWith(
                      maxPvVoltage: v,
                      clearMaxPvVoltage: v == null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _num(
                  'MPPT min (V)',
                  inverter.mpptMinV,
                  (v) => provider.setSelectedInverter(
                    inverter.copyWith(mpptMinV: v, clearMpptMin: v == null),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _num(
                  'MPPT max (V)',
                  inverter.mpptMaxV,
                  (v) => provider.setSelectedInverter(
                    inverter.copyWith(mpptMaxV: v, clearMpptMax: v == null),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromLibrary(BuildContext context) async {
    final library = context.read<EquipmentLibraryProvider>();
    final provider = context.read<ProjectProvider>();
    final selected = await showDialog<InverterSpec>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select an inverter'),
        children: [
          if (library.inverters.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No saved inverters yet.'),
            ),
          for (final item in library.inverters)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item.spec),
              child: Text(
                '${item.name} — ${item.spec.ratedOutputW.toStringAsFixed(0)}W',
              ),
            ),
        ],
      ),
    );
    if (selected != null) await provider.setSelectedInverter(selected);
  }
}

class _StringPlannerForm extends StatelessWidget {
  final SolarProject project;
  final StringPlanningResult result;
  final InverterSpec inverter;
  const _StringPlannerForm({
    required this.project,
    required this.result,
    required this.inverter,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProjectProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _num(
                'Panels per string',
                project.stringPanelsPerString.toDouble(),
                (v) => provider.setStringLayout(
                  (v ?? 1).round(),
                  project.stringParallelStrings,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _num(
                'Parallel strings',
                project.stringParallelStrings.toDouble(),
                (v) => provider.setStringLayout(
                  project.stringPanelsPerString,
                  (v ?? 1).round(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            _stat('Total panels', '${result.totalPanels}'),
            _stat('String Vmp', '${result.stringVmp.toStringAsFixed(1)} V'),
            _stat('String Voc', '${result.stringVoc.toStringAsFixed(1)} V'),
            _stat(
              'String current',
              '${result.stringCurrentA.toStringAsFixed(1)} A',
            ),
            _stat(
              'Approx. array power',
              '${result.approximateArrayPowerW.toStringAsFixed(0)} W',
            ),
          ],
        ),
        if (!inverter.isEmpty && inverter.maxPvVoltage != null) ...[
          const SizedBox(height: 8),
          Text(
            result.stringVoc <= inverter.maxPvVoltage!
                ? 'String Voc is within the entered inverter max PV voltage.'
                : 'String Voc exceeds the entered inverter max PV voltage.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: result.stringVoc <= inverter.maxPvVoltage!
                  ? Colors.green.shade700
                  : Colors.orange.shade800,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          StringPlanningResult.temperatureDisclaimer,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _stat(String label, String value) => SizedBox(
    width: 140,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

Widget _text(String label, String value, ValueChanged<String> onChanged) {
  return TextField(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    controller: TextEditingController(text: value)
      ..selection = TextSelection.collapsed(offset: value.length),
    onChanged: onChanged,
  );
}

Widget _num(String label, double? value, ValueChanged<double?> onChanged) {
  final text = value == null || value == 0 ? '' : value.toString();
  return TextField(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    controller: TextEditingController(text: text)
      ..selection = TextSelection.collapsed(offset: text.length),
    onChanged: (v) => onChanged(double.tryParse(v)),
  );
}
