import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../models/project_status.dart';
import '../../state/project_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';

/// Project Workspace details: optional description/site/client metadata,
/// free-text notes, review status, and the local activity timeline.
class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late TextEditingController _description;
  late TextEditingController _projectType;
  late TextEditingController _siteLabel;
  late TextEditingController _clientReference;
  late TextEditingController _installationNotes;
  late TextEditingController _notes;
  String? _initializedForProjectId;

  void _initFrom(SolarProject project) {
    _description = TextEditingController(text: project.description);
    _projectType = TextEditingController(text: project.projectType);
    _siteLabel = TextEditingController(text: project.siteLabel);
    _clientReference = TextEditingController(text: project.clientReference);
    _installationNotes = TextEditingController(text: project.installationNotes);
    _notes = TextEditingController(text: project.notes);
    _initializedForProjectId = project.id;
  }

  void _saveAll(ProjectProvider provider) {
    provider.updateProjectDetails(
      description: _description.text,
      projectType: _projectType.text,
      siteLabel: _siteLabel.text,
      clientReference: _clientReference.text,
      installationNotes: _installationNotes.text,
      notes: _notes.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final project = provider.activeProject;
          if (project == null) {
            return Center(
              child: EmptyState(
                icon: Icons.description_outlined,
                title: 'No active project',
                message: 'Open a project to edit its details and notes.',
              ),
            );
          }
          if (_initializedForProjectId != project.id) {
            _initFrom(project);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusBadge(status: project.status),
              const SizedBox(height: 12),
              if (project.status != ProjectStatus.reviewed)
                OutlinedButton.icon(
                  onPressed: () => provider.setManuallyReviewed(true),
                  icon: const Icon(Icons.task_alt, size: 16),
                  label: const Text('Mark as Reviewed'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => provider.setManuallyReviewed(false),
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Clear Review Mark'),
                ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Overview',
                icon: Icons.description_outlined,
                child: Column(
                  children: [
                    TextField(
                      controller: _description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _saveAll(provider),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _projectType,
                      decoration: const InputDecoration(
                        labelText: 'Project type (optional)',
                        hintText: 'e.g. Residential, Commercial',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _saveAll(provider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Site & reference (optional)',
                icon: Icons.place_outlined,
                child: Column(
                  children: [
                    TextField(
                      controller: _siteLabel,
                      decoration: const InputDecoration(
                        labelText: 'Site / project label',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _saveAll(provider),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _clientReference,
                      decoration: const InputDecoration(
                        labelText: 'Client / reference name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _saveAll(provider),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _installationNotes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Roof / installation notes',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _saveAll(provider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Notes',
                icon: Icons.sticky_note_2_outlined,
                child: TextField(
                  controller: _notes,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Roof has partial afternoon shading. Water pump excluded from backup.',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _saveAll(provider),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Activity',
                icon: Icons.history,
                child: project.activity.isEmpty
                    ? const Text(
                        'No activity recorded yet.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : Column(
                        children: [
                          for (final entry in project.activity.reversed.take(
                            30,
                          ))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      _formatDate(entry.timestamp),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.message,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';

  static String _month(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}

class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ProjectStatus.draft => Colors.grey.shade600,
      ProjectStatus.readyForReview => Colors.blue.shade700,
      ProjectStatus.reviewed => Colors.green.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
