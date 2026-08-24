import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../models/report_options.dart';
import '../../services/report_pdf_service.dart';
import '../../state/project_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';

const _pdfService = ReportPdfService();

/// Report preview + generation. Toggles control optional sections; core
/// technical assumptions and the disclaimer are always included and are
/// not removable.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportOptions _options = const ReportOptions();
  String? _error;
  bool _busy = false;

  Future<void> _generateAndShare(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final rec = provider.systemRecommendation;
    final project = provider.activeProject;
    if (rec == null || project == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await _pdfService.buildReport(
        rec: rec,
        project: project,
        options: _options,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${_safeFileName(project.name)}_solar_report.pdf',
      );
      await provider.logReportGenerated();
    } catch (_) {
      setState(
        () => _error = 'The report could not be generated. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    final rec = provider.systemRecommendation;
    final project = provider.activeProject;
    if (rec == null || project == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Printing.layoutPdf(
        onLayout: (format) => _pdfService.buildReport(
          rec: rec,
          project: project,
          options: _options,
        ),
      );
    } catch (_) {
      setState(() => _error = 'The report preview could not be generated.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _safeFileName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_').toLowerCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.activeProject;
          if (project == null) {
            return Center(
              child: EmptyState(
                icon: Icons.description_outlined,
                title: 'No active project',
                message: 'Open a project to generate a Solar Planning Report.',
              ),
            );
          }
          if (!provider.hasValidResults) {
            return Center(
              child: EmptyState(
                icon: Icons.info_outline,
                title: 'Not report-ready yet',
                message:
                    'Add appliances and confirm solar assumptions before generating a report.',
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: 'Include in report',
                icon: Icons.tune,
                child: Column(
                  children: [
                    _toggle(
                      'Appliance details',
                      _options.includeAppliances,
                      (v) => setState(
                        () =>
                            _options = _options.copyWith(includeAppliances: v),
                      ),
                    ),
                    _toggle(
                      'Equipment specifications',
                      _options.includeEquipment,
                      (v) => setState(
                        () => _options = _options.copyWith(includeEquipment: v),
                      ),
                    ),
                    _toggle(
                      'Design scenarios',
                      _options.includeScenarios,
                      (v) => setState(
                        () => _options = _options.copyWith(includeScenarios: v),
                      ),
                    ),
                    _toggle(
                      'Cost / savings estimate',
                      _options.includeCost,
                      (v) => setState(
                        () => _options = _options.copyWith(includeCost: v),
                      ),
                    ),
                    _toggle(
                      'Project notes',
                      _options.includeNotes,
                      (v) => setState(
                        () => _options = _options.copyWith(includeNotes: v),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Core assumptions and the planning disclaimer are always included.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _preview(context),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview Report'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _generateAndShare(context),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Generate & Share PDF'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => provider.shareSummary(),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Summary'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Generated entirely on this device — no account, no backend, and no upload of your '
                'project data.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
