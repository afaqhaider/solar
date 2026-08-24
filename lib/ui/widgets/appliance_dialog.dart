import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appliance.dart';
import '../../models/appliance_presets.dart';
import '../../models/load_category.dart';
import '../../state/project_provider.dart';

/// Add/edit dialog for a single appliance (load). Presets pre-fill editable
/// example values — never treated as guaranteed manufacturer specs.
class ApplianceDialog extends StatefulWidget {
  final Appliance? appliance;
  const ApplianceDialog({super.key, this.appliance});

  @override
  State<ApplianceDialog> createState() => _ApplianceDialogState();
}

class _ApplianceDialogState extends State<ApplianceDialog> {
  late TextEditingController _nameController;
  late TextEditingController _wattageController;
  late TextEditingController _quantityController;
  late TextEditingController _hoursController;
  late TextEditingController _surgeController;
  double _daysPerWeek = 7;
  String _category = 'Custom';
  bool _backupRequired = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final a = widget.appliance;
    _nameController = TextEditingController(text: a?.name ?? '');
    _wattageController = TextEditingController(
      text: a == null || a.wattage == 0 ? '' : a.wattage.toString(),
    );
    _quantityController = TextEditingController(
      text: (a?.quantity ?? 1).toString(),
    );
    _hoursController = TextEditingController(
      text: a == null || a.usageHours == 0 ? '' : a.usageHours.toString(),
    );
    _surgeController = TextEditingController(
      text: a?.surgeWattage?.toString() ?? '',
    );
    _daysPerWeek = a?.daysPerWeek ?? 7;
    _category = a?.category ?? 'Custom';
    _backupRequired = a?.backupRequired ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wattageController.dispose();
    _quantityController.dispose();
    _hoursController.dispose();
    _surgeController.dispose();
    super.dispose();
  }

  void _applyPreset(AppliancePreset preset) {
    setState(() {
      _nameController.text = preset.name;
      _wattageController.text = preset.defaultWattage == 0
          ? ''
          : preset.defaultWattage.toInt().toString();
      _hoursController.text = preset.defaultUsageHours.toString();
      _surgeController.text =
          preset.defaultSurgeWattage?.toInt().toString() ?? '';
      _category = preset.category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.appliance == null ? 'Add Appliance' : 'Edit Appliance',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AppliancePreset>(
                  decoration: const InputDecoration(
                    labelText: 'Common Presets (editable examples)',
                  ),
                  items: AppliancePresets.list
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (p) => p != null ? _applyPreset(p) : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Appliance name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: {...LoadCategories.suggested, _category}
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (c) => setState(() => _category = c ?? _category),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _wattageController,
                        decoration: const InputDecoration(
                          labelText: 'Watts (W)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final d = double.tryParse(v ?? '');
                          if (d == null || d < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final i = int.tryParse(v ?? '');
                          if (i == null || i < 1) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hoursController,
                  decoration: const InputDecoration(
                    labelText: 'Hours used per day',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val <= 0) return 'Invalid';
                    if (val > 24) return 'Max 24h';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _surgeController,
                  decoration: const InputDecoration(
                    labelText: 'Startup / surge wattage (optional)',
                    helperText:
                        'For motor-driven appliances (fridges, pumps, A/C).',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    return double.tryParse(v) == null ? 'Invalid' : null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Days used per week',
                      style: TextStyle(fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: _daysPerWeek,
                        min: 1,
                        max: 7,
                        divisions: 6,
                        label: _daysPerWeek.toStringAsFixed(0),
                        onChanged: (v) => setState(() => _daysPerWeek = v),
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      child: Text(_daysPerWeek.toStringAsFixed(0)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _backupRequired,
                  onChanged: (v) => setState(() => _backupRequired = v),
                  title: const Text(
                    'Backup required',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Included in the Essential Load Profile used for battery and inverter backup sizing.',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final appliance = Appliance(
                id: widget.appliance?.id,
                name: _nameController.text,
                category: _category,
                wattage: double.parse(_wattageController.text),
                quantity: int.parse(_quantityController.text),
                usageHours: double.parse(_hoursController.text),
                daysPerWeek: _daysPerWeek,
                surgeWattage: double.tryParse(_surgeController.text),
                enabled: widget.appliance?.enabled ?? true,
                backupRequired: _backupRequired,
              );
              final provider = context.read<ProjectProvider>();
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
