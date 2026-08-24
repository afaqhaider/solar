import 'dart:convert';
import '../models/project.dart';

/// Raised when an imported project file fails validation. The message is
/// always human-readable — never a raw stack trace.
class ProjectImportException implements Exception {
  final String message;
  const ProjectImportException(this.message);
  @override
  String toString() => message;
}

/// Structured JSON export/import for a single project, with schema-version
/// and field validation so malformed or unsupported input is rejected with
/// a clear error rather than crashing or silently corrupting app state.
class ProjectExportService {
  const ProjectExportService();

  static const int currentSchemaVersion = 1;
  static const int minSupportedSchemaVersion = 1;

  Map<String, dynamic> exportProject(SolarProject project) => {
    'schemaVersion': currentSchemaVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'app': 'Solar Calculator',
    'project': project.toJson(),
  };

  String exportProjectToJsonString(SolarProject project) =>
      const JsonEncoder.withIndent('  ').convert(exportProject(project));

  /// Parses and validates an exported project JSON string. Never trusts
  /// the input blindly — checks format, schema version and required
  /// fields/ranges before constructing a [SolarProject].
  SolarProject importProjectFromJsonString(String jsonString) {
    Map<String, dynamic> root;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw const ProjectImportException(
          'This file is not a Solar Calculator project export.',
        );
      }
      root = decoded;
    } on ProjectImportException {
      rethrow;
    } catch (_) {
      throw const ProjectImportException(
        'This file could not be read as valid JSON.',
      );
    }

    final schemaVersion = root['schemaVersion'];
    if (schemaVersion is! int) {
      throw const ProjectImportException(
        'This file is missing a schema version and cannot be imported.',
      );
    }
    if (schemaVersion < minSupportedSchemaVersion ||
        schemaVersion > currentSchemaVersion) {
      throw ProjectImportException(
        'This file uses project schema version $schemaVersion, which this app version does not support.',
      );
    }

    final projectJson = root['project'];
    if (projectJson is! Map<String, dynamic>) {
      throw const ProjectImportException(
        'This file does not contain project data.',
      );
    }

    _validateRequiredFields(projectJson);

    try {
      return SolarProject.fromJson(projectJson);
    } catch (_) {
      throw const ProjectImportException(
        'This project file is corrupted and could not be loaded.',
      );
    }
  }

  void _validateRequiredFields(Map<String, dynamic> json) {
    if (json['id'] is! String || (json['id'] as String).isEmpty) {
      throw const ProjectImportException(
        'This project file is missing a required project ID.',
      );
    }
    if (json['name'] is! String) {
      throw const ProjectImportException(
        'This project file is missing a project name.',
      );
    }

    // Numeric range sanity checks — reject obviously invalid values rather
    // than silently constructing a broken project.
    final numericRanges = <String, (num, num)>{
      'peakSunHours': (0, 24),
      'systemEfficiencyPercent': (0, 100),
      'designReservePercent': (0, 1000),
      'panelWattage': (0, 100000),
      'batteryDoD': (0, 100),
      'batteryEfficiencyPercent': (0, 100),
      'inverterHeadroomPercent': (0, 95),
    };
    for (final entry in numericRanges.entries) {
      final value = json[entry.key];
      if (value == null) continue;
      if (value is! num || value.isNaN || value.isInfinite) {
        throw ProjectImportException(
          'This project file has an invalid value for "${entry.key}".',
        );
      }
      final (min, max) = entry.value;
      if (value < min || value > max) {
        throw ProjectImportException(
          'This project file has an out-of-range value for "${entry.key}".',
        );
      }
    }

    final appliances = json['appliances'];
    if (appliances != null && appliances is! List) {
      throw const ProjectImportException(
        'This project file has malformed appliance data.',
      );
    }
  }
}
