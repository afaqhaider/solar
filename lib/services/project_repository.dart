import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';

/// Local, offline persistence for saved solar projects and user
/// preferences. Backed by [SharedPreferences] to match the app's existing
/// storage technology — no backend, no auth.
class ProjectRepository {
  static const _projectsKey = 'solar_projects_v1';
  static const _activeProjectIdKey = 'solar_active_project_id_v1';

  Future<List<SolarProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_projectsKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded
        .map((e) => SolarProject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProjects(List<SolarProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(projects.map((p) => p.toJson()).toList());
    await prefs.setString(_projectsKey, encoded);
  }

  Future<String?> loadActiveProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProjectIdKey);
  }

  Future<void> saveActiveProjectId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeProjectIdKey);
    } else {
      await prefs.setString(_activeProjectIdKey, id);
    }
  }
}
