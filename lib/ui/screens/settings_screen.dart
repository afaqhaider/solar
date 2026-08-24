import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/project_export_service.dart';
import '../../state/project_provider.dart';
import '../../state/settings_provider.dart';
import 'glossary_screen.dart';
import 'help_center_screen.dart';
import 'onboarding_screen.dart';

/// App-wide settings: appearance, convenience defaults for new projects,
/// local data management, and help.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final projects = context.watch<ProjectProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Appearance'),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (m) => settings.setThemeMode(m!),
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('System'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Light'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Dark'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Units'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Electrical values are always displayed in standard SI units (W/kW, Wh/kWh, V, A, Ah), '
                'switching automatically between the two based on magnitude.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Defaults for New Projects'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _defaultField(
                    'Default currency label',
                    settings.defaultCurrencyLabel ?? '\$',
                    (v) => settings.setDefaultCurrency(v),
                  ),
                  const SizedBox(height: 10),
                  _defaultNumberField(
                    'Default system efficiency (%)',
                    settings.defaultEfficiencyPercent,
                    (v) => settings.setDefaultEfficiency(v),
                  ),
                  const SizedBox(height: 10),
                  _defaultNumberField(
                    'Default solar reserve (%)',
                    settings.defaultReservePercent,
                    (v) => settings.setDefaultReserve(v),
                  ),
                  const SizedBox(height: 10),
                  _defaultNumberField(
                    'Default inverter headroom (%)',
                    settings.defaultHeadroomPercent,
                    (v) => settings.setDefaultHeadroom(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: const Text('Export active project'),
                  subtitle: const Text(
                    'Share a JSON file that can be imported later',
                  ),
                  onTap: projects.activeProject == null
                      ? null
                      : () => _exportActiveProject(context, projects),
                ),
                ListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: const Text('Import project'),
                  subtitle: const Text('From a previously exported JSON file'),
                  onTap: () => _importProject(context, projects),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Delete all local projects',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => _confirmDeleteAll(context, projects),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Help'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Replay onboarding'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OnboardingScreen(
                        onFinished: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help Center'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Glossary'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GlossaryScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: Colors.grey,
      ),
    ),
  );

  Widget _defaultField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
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

  Widget _defaultNumberField(
    String label,
    double? value,
    ValueChanged<double?> onChanged,
  ) {
    final text = value?.toString() ?? '';
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

  Future<void> _exportActiveProject(
    BuildContext context,
    ProjectProvider provider,
  ) async {
    try {
      final json = provider.exportActiveProjectJson();
      final dir = await getTemporaryDirectory();
      final name = (provider.activeProject?.name ?? 'project').replaceAll(
        RegExp(r'[^A-Za-z0-9_-]+'),
        '_',
      );
      final file = File('${dir.path}/${name}_solar_project.json');
      await file.writeAsString(json);
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Solar project export');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not export the project. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _importProject(
    BuildContext context,
    ProjectProvider provider,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final imported = await provider.importProjectJson(content);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported "${imported.name}" as a new project.'),
          ),
        );
      }
    } on ProjectImportException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This file could not be imported.')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAll(
    BuildContext context,
    ProjectProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Local Projects?'),
        content: const Text(
          'This permanently removes every saved project on this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.deleteAllProjects();
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Solar Calculator',
      applicationVersion: '1.0.0',
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'A project-based solar system planner and sizing utility. All data stays on this device '
            'unless you explicitly export or share it.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
