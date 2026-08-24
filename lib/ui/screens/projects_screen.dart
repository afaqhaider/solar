import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../state/project_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/tab_controller.dart';
import '../widgets/empty_state.dart';
import 'project_details_screen.dart';
import 'settings_screen.dart';

/// Saved solar planning projects: create, switch, rename, duplicate,
/// delete, search and sort.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _query = '';
  ProjectSortOrder _sort = ProjectSortOrder.recentlyModified;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateProjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          if (provider.projects.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.folder_open,
                  title: 'No saved projects',
                  message: 'Create a project to start planning a solar system.',
                  actionLabel: 'New Project',
                  onAction: () => showCreateProjectDialog(context),
                ),
              ),
            );
          }

          final results = provider.searchProjects(_query, _sort);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search projects',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<ProjectSortOrder>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Sort',
                      onSelected: (order) => setState(() => _sort = order),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: ProjectSortOrder.recentlyModified,
                          child: Text('Recently modified'),
                        ),
                        PopupMenuItem(
                          value: ProjectSortOrder.recentlyCreated,
                          child: Text('Recently created'),
                        ),
                        PopupMenuItem(
                          value: ProjectSortOrder.name,
                          child: Text('Name'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (results.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No projects match your search.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final project = results[index];
                      final isActive = project.id == provider.activeProject?.id;
                      return Card(
                        color: isActive
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            isActive
                                ? Icons.check_circle
                                : Icons.folder_outlined,
                          ),
                          title: Text(
                            project.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${project.status.label} · ${project.appliances.length} appliances · updated ${_formatDate(project.updatedAt)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            provider.setActiveProject(project.id);
                            context.read<SolarTabController>().goTo(
                              SolarTabController.dashboard,
                            );
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) => _handleAction(
                              context,
                              provider,
                              project,
                              action,
                            ),
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'open', child: Text('Open')),
                              PopupMenuItem(
                                value: 'details',
                                child: Text('Edit Details'),
                              ),
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('Rename'),
                              ),
                              PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Duplicate'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _handleAction(
    BuildContext context,
    ProjectProvider provider,
    SolarProject project,
    String action,
  ) {
    switch (action) {
      case 'open':
        provider.setActiveProject(project.id);
        context.read<SolarTabController>().goTo(SolarTabController.dashboard);
        break;
      case 'details':
        provider.setActiveProject(project.id);
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProjectDetailsScreen()));
        break;
      case 'rename':
        _showRenameDialog(context, provider, project);
        break;
      case 'duplicate':
        provider.duplicateProject(project.id);
        break;
      case 'delete':
        _showDeleteDialog(context, provider, project);
        break;
    }
  }

  void _showRenameDialog(
    BuildContext context,
    ProjectProvider provider,
    SolarProject project,
  ) {
    final controller = TextEditingController(text: project.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.renameProject(project.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ProjectProvider provider,
    SolarProject project,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          '"${project.name}" and all its appliances will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteProject(project.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Shown from the Dashboard's empty state and quick action, as well as the
/// Projects screen's FAB.
void showCreateProjectDialog(BuildContext context) {
  final controller = TextEditingController();
  final provider = context.read<ProjectProvider>();
  final settings = context.read<SettingsProvider>();
  final tabs = context.read<SolarTabController>();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New Solar Project'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Project name',
          hintText: 'e.g. Home Rooftop System',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await provider.createProject(
              controller.text,
              defaultSystemEfficiencyPercent: settings.defaultEfficiencyPercent,
              defaultDesignReservePercent: settings.defaultReservePercent,
              defaultInverterHeadroomPercent: settings.defaultHeadroomPercent,
              defaultCurrencyLabel: settings.defaultCurrencyLabel,
            );
            if (context.mounted) {
              Navigator.pop(context);
              tabs.goTo(SolarTabController.loads);
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
