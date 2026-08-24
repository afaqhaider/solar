import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/equipment_specs.dart';
import '../../state/equipment_library_provider.dart';
import '../widgets/empty_state.dart';

/// "My Equipment" — a small reusable local library of panel, battery and
/// inverter specifications a user can select into any project.
class EquipmentLibraryScreen extends StatelessWidget {
  const EquipmentLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Equipment'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Panels'),
              Tab(text: 'Batteries'),
              Tab(text: 'Inverters'),
            ],
          ),
        ),
        body: Consumer<EquipmentLibraryProvider>(
          builder: (context, library, _) {
            if (library.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return TabBarView(
              children: [
                _PanelsTab(library: library),
                _BatteriesTab(library: library),
                _InvertersTab(library: library),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PanelsTab extends StatelessWidget {
  final EquipmentLibraryProvider library;
  const _PanelsTab({required this.library});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Panel'),
        onPressed: () => _editPanel(context, null),
      ),
      body: library.panels.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.grid_view,
                title: 'No saved panels',
                message:
                    'Save a panel spec here (e.g. "550W Mono Panel") to reuse it across projects.',
                actionLabel: 'Add Panel',
                onAction: () => _editPanel(context, null),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in library.panels)
                  Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.spec.ratedPowerW.toStringAsFixed(0)} W'
                        '${item.spec.vmp != null ? ' · Vmp ${item.spec.vmp!.toStringAsFixed(1)}V' : ''}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (a) {
                          if (a == 'edit') _editPanel(context, item);
                          if (a == 'duplicate') library.duplicatePanel(item.id);
                          if (a == 'delete') library.deletePanel(item.id);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicate'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 72),
              ],
            ),
    );
  }

  Future<void> _editPanel(BuildContext context, dynamic item) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final wattController = TextEditingController(
      text: item?.spec.ratedPowerW == null || item?.spec.ratedPowerW == 0
          ? ''
          : item.spec.ratedPowerW.toString(),
    );
    final vmpController = TextEditingController(
      text: item?.spec.vmp?.toString() ?? '',
    );
    final vocController = TextEditingController(
      text: item?.spec.voc?.toString() ?? '',
    );
    final impController = TextEditingController(
      text: item?.spec.imp?.toString() ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Panel' : 'Edit Panel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. "550W Mono Panel")',
                ),
              ),
              TextField(
                controller: wattController,
                decoration: const InputDecoration(labelText: 'Rated power (W)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: vmpController,
                decoration: const InputDecoration(
                  labelText: 'Vmp (V, optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: vocController,
                decoration: const InputDecoration(
                  labelText: 'Voc (V, optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: impController,
                decoration: const InputDecoration(
                  labelText: 'Imp (A, optional)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final spec = PanelSpec(
      ratedPowerW: double.tryParse(wattController.text) ?? 0,
      vmp: double.tryParse(vmpController.text),
      voc: double.tryParse(vocController.text),
      imp: double.tryParse(impController.text),
    );
    final name = nameController.text.trim().isEmpty
        ? 'Panel'
        : nameController.text.trim();
    if (item == null) {
      await library.addPanel(name, spec);
    } else {
      await library.updatePanel(item.id, name, spec);
    }
  }
}

class _BatteriesTab extends StatelessWidget {
  final EquipmentLibraryProvider library;
  const _BatteriesTab({required this.library});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Battery'),
        onPressed: () => _editBattery(context, null),
      ),
      body: library.batteries.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.battery_std,
                title: 'No saved batteries',
                message:
                    'Save a battery spec here (e.g. "12V 200Ah AGM") to reuse it across projects.',
                actionLabel: 'Add Battery',
                onAction: () => _editBattery(context, null),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in library.batteries)
                  Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.spec.nominalVoltage.toStringAsFixed(0)}V ${item.spec.capacityAh.toStringAsFixed(0)}Ah',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (a) {
                          if (a == 'edit') _editBattery(context, item);
                          if (a == 'duplicate') {
                            library.duplicateBattery(item.id);
                          }
                          if (a == 'delete') library.deleteBattery(item.id);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicate'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 72),
              ],
            ),
    );
  }

  Future<void> _editBattery(BuildContext context, dynamic item) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final voltController = TextEditingController(
      text: item?.spec.nominalVoltage == null || item?.spec.nominalVoltage == 0
          ? ''
          : item.spec.nominalVoltage.toString(),
    );
    final ahController = TextEditingController(
      text: item?.spec.capacityAh == null || item?.spec.capacityAh == 0
          ? ''
          : item.spec.capacityAh.toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Battery' : 'Edit Battery'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. "12V 200Ah AGM")',
                ),
              ),
              TextField(
                controller: voltController,
                decoration: const InputDecoration(
                  labelText: 'Nominal voltage (V)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: ahController,
                decoration: const InputDecoration(labelText: 'Capacity (Ah)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final spec = BatteryEquipmentSpec(
      nominalVoltage: double.tryParse(voltController.text) ?? 0,
      capacityAh: double.tryParse(ahController.text) ?? 0,
    );
    final name = nameController.text.trim().isEmpty
        ? 'Battery'
        : nameController.text.trim();
    if (item == null) {
      await library.addBattery(name, spec);
    } else {
      await library.updateBattery(item.id, name, spec);
    }
  }
}

class _InvertersTab extends StatelessWidget {
  final EquipmentLibraryProvider library;
  const _InvertersTab({required this.library});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Inverter'),
        onPressed: () => _editInverter(context, null),
      ),
      body: library.inverters.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.dns,
                title: 'No saved inverters',
                message:
                    'Save an inverter spec here (e.g. "5kW Hybrid") to reuse it across projects.',
                actionLabel: 'Add Inverter',
                onAction: () => _editInverter(context, null),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in library.inverters)
                  Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.spec.ratedOutputW.toStringAsFixed(0)} W',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (a) {
                          if (a == 'edit') _editInverter(context, item);
                          if (a == 'duplicate') {
                            library.duplicateInverter(item.id);
                          }
                          if (a == 'delete') library.deleteInverter(item.id);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicate'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 72),
              ],
            ),
    );
  }

  Future<void> _editInverter(BuildContext context, dynamic item) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final wattController = TextEditingController(
      text: item?.spec.ratedOutputW == null || item?.spec.ratedOutputW == 0
          ? ''
          : item.spec.ratedOutputW.toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Inverter' : 'Edit Inverter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. "5kW Hybrid")',
                ),
              ),
              TextField(
                controller: wattController,
                decoration: const InputDecoration(
                  labelText: 'Rated output (W)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final spec = InverterSpec(
      ratedOutputW: double.tryParse(wattController.text) ?? 0,
    );
    final name = nameController.text.trim().isEmpty
        ? 'Inverter'
        : nameController.text.trim();
    if (item == null) {
      await library.addInverter(name, spec);
    } else {
      await library.updateInverter(item.id, name, spec);
    }
  }
}
