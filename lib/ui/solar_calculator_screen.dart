import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appliance.dart';
import '../models/appliance_presets.dart';
import '../models/solar_result.dart';
import '../logic/solar_provider.dart';

class SolarCalculatorScreen extends StatelessWidget {
  const SolarCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Solar Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('by SSCodeAxis', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => context.read<SolarProvider>().shareResults(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.red),
            onPressed: () => _showResetDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplianceDialog(context),
        label: const Text('Add Appliance'),
        icon: const Icon(Icons.add),
      ),
      body: Consumer<SolarProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              const SizedBox(height: 8),
              _SectionHeader(title: '1. Electrical Load', icon: Icons.settings),
              if (provider.appliances.isEmpty)
                GestureDetector(
                  onTap: () => _showApplianceDialog(context),
                  child: const _EmptyLoadState(),
                )
              else
                ...provider.appliances.map((a) => _ApplianceItem(
                      appliance: a,
                      onEdit: () => _showApplianceDialog(context, appliance: a),
                      onDelete: () => provider.deleteAppliance(a.id),
                    )),
              const SizedBox(height: 16),
              _SectionHeader(title: '2. Solar Parameters', icon: Icons.wb_sunny),
              _SolarParametersCard(provider: provider),
              const SizedBox(height: 16),
              _SectionHeader(title: '3. System & Battery', icon: Icons.battery_charging_full),
              _SystemOptionsCard(provider: provider),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => provider.calculate(),
                  child: const Text('Calculate Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              if (provider.result != null) _ResultSummaryCard(result: provider.result!),
              const SizedBox(height: 16),
              const _CalculationExplanation(),
              const SizedBox(height: 16),
              const _DisclaimerText(),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solar Calculator'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A simple offline tool for estimating solar panel, inverter, and battery requirements.'),
            SizedBox(height: 12),
            Text('Developer: SSCodeAxis', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Version: 1.0.0', style: TextStyle(fontSize: 12)),
            Divider(),
            Text(
              'Disclaimer: This app provides estimates for planning purposes. Actual system requirements vary based on equipment and conditions.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Calculator?'),
        content: const Text('All entered appliances and custom parameters will be cleared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<SolarProvider>().reset();
              Navigator.pop(context);
            },
            child: const Text('Reset All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showApplianceDialog(BuildContext context, {Appliance? appliance}) {
    showDialog(
      context: context,
      builder: (context) => _ApplianceDialog(appliance: appliance),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplianceItem extends StatelessWidget {
  final Appliance appliance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ApplianceItem({required this.appliance, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appliance.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${appliance.wattage.toInt()}W x ${appliance.quantity} @ ${appliance.usageHours}h',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              _formatWh(appliance.dailyWh),
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }

  String _formatWh(double wh) => wh >= 1000 ? '${(wh / 1000).toStringAsFixed(2)} kWh' : '${wh.toStringAsFixed(0)} Wh';
}

class _EmptyLoadState extends StatelessWidget {
  const _EmptyLoadState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 8),
            const Text('No appliances added', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Add appliances to start calculating.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SolarParametersCard extends StatelessWidget {
  final SolarProvider provider;
  const _SolarParametersCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Peak Sun Hours',
                  errorText: provider.errors['peakSunHours'],
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: provider.peakSunHours)..selection = TextSelection.collapsed(offset: provider.peakSunHours.length),
                onChanged: (v) => provider.updateField('peakSunHours', v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Efficiency (%)',
                  errorText: provider.errors['efficiency'],
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: provider.efficiency)..selection = TextSelection.collapsed(offset: provider.efficiency.length),
                onChanged: (v) => provider.updateField('efficiency', v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemOptionsCard extends StatelessWidget {
  final SolarProvider provider;
  const _SystemOptionsCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Solar Panel Wattage (W)',
                errorText: provider.errors['panelWattage'],
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: provider.panelWattage)..selection = TextSelection.collapsed(offset: provider.panelWattage.length),
              onChanged: (v) => provider.updateField('panelWattage', v),
            ),
            const Divider(height: 24),
            const Text('Battery Backup Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Required Backup (Hours)',
                errorText: provider.errors['backupHours'],
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: provider.backupHours)..selection = TextSelection.collapsed(offset: provider.backupHours.length),
              onChanged: (v) => provider.updateField('backupHours', v),
            ),
            if ((double.tryParse(provider.backupHours) ?? 0) > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Voltage', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: provider.batteryVoltage)..selection = TextSelection.collapsed(offset: provider.batteryVoltage.length),
                      onChanged: (v) => provider.updateField('batteryVoltage', v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Ah', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: provider.batteryAh)..selection = TextSelection.collapsed(offset: provider.batteryAh.length),
                      onChanged: (v) => provider.updateField('batteryAh', v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'DoD %', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: provider.batteryDoD)..selection = TextSelection.collapsed(offset: provider.batteryDoD.length),
                      onChanged: (v) => provider.updateField('batteryDoD', v),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultSummaryCard extends StatelessWidget {
  final SolarResult result;
  const _ResultSummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Recommended System', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Required Solar Array', style: TextStyle(fontSize: 12)),
            Text(
              _formatWatts(result.requiredSolarArrayW),
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ResultMetric(label: 'Panels', value: '${result.panelCount}', sub: '${result.panelWattage.toInt()}W'),
                _ResultMetric(label: 'Capacity', value: _formatWatts(result.installedSolarCapacityW), sub: 'Installed'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ResultMetric(label: 'Inverter', value: _formatWatts(result.minInverterCapacityW), sub: 'Min.'),
                if (result.batteryBackupEnabled)
                  _ResultMetric(label: 'Batteries', value: '${result.batteryCount}', sub: '${result.batteryVoltage.toInt()}V ${result.batteryAh.toInt()}Ah'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatWatts(double w) => w >= 1000 ? '${(w / 1000).toStringAsFixed(2)} kW' : '${w.toStringAsFixed(0)} W';
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _ResultMetric({required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _CalculationExplanation extends StatefulWidget {
  const _CalculationExplanation();

  @override
  State<_CalculationExplanation> createState() => _CalculationExplanationState();
}

class _CalculationExplanationState extends State<_CalculationExplanation> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text('How is this calculated?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.help_outline, size: 20),
        childrenPadding: const EdgeInsets.all(16),
        children: const [
          Text('• Solar Array: Daily Wh / Sun Hours / Efficiency', style: TextStyle(fontSize: 12)),
          Text('• Panels: Required Array / Panel Wattage (rounded up)', style: TextStyle(fontSize: 12)),
          Text('• Inverter: Total Load / 0.80 (20% headroom)', style: TextStyle(fontSize: 12)),
          Text('• Battery: (Load * Backup Hours) / Usable Battery Wh', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _DisclaimerText extends StatelessWidget {
  const _DisclaimerText();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        'Estimates are for planning purposes. Actual requirements may vary.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }
}

class _ApplianceDialog extends StatefulWidget {
  final Appliance? appliance;
  const _ApplianceDialog({this.appliance});

  @override
  State<_ApplianceDialog> createState() => _ApplianceDialogState();
}

class _ApplianceDialogState extends State<_ApplianceDialog> {
  late TextEditingController _nameController;
  late TextEditingController _wattageController;
  late TextEditingController _quantityController;
  late TextEditingController _hoursController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.appliance?.name ?? '');
    _wattageController = TextEditingController(text: widget.appliance?.wattage == 0 ? '' : widget.appliance?.wattage.toString() ?? '');
    _quantityController = TextEditingController(text: widget.appliance?.quantity.toString() ?? '1');
    _hoursController = TextEditingController(text: widget.appliance?.usageHours == 0 ? '' : widget.appliance?.usageHours.toString() ?? '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wattageController.dispose();
    _quantityController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _applyPreset(AppliancePreset preset) {
    setState(() {
      _nameController.text = preset.name;
      _wattageController.text = preset.defaultWattage.toInt().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.appliance == null ? 'Add Appliance' : 'Edit Appliance'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<AppliancePreset>(
                decoration: const InputDecoration(labelText: 'Common Presets'),
                items: AppliancePresets.list.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (p) => p != null ? _applyPreset(p) : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _wattageController,
                      decoration: const InputDecoration(labelText: 'Watts', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hoursController,
                decoration: const InputDecoration(labelText: 'Daily Usage Hours', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null) return 'Invalid';
                  if (val > 24) return 'Max 24h';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final appliance = Appliance(
                id: widget.appliance?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                wattage: double.parse(_wattageController.text),
                quantity: int.parse(_quantityController.text),
                usageHours: double.parse(_hoursController.text),
              );
              final provider = context.read<SolarProvider>();
              if (widget.appliance == null) {
                provider.addAppliance(appliance);
              } else {
                provider.updateAppliance(appliance);
              }
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
