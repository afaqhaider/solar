import 'package:uuid/uuid.dart';
import 'planning_inputs.dart';

/// A named, saved snapshot of [PlanningInputs] for What-If exploration and
/// side-by-side comparison. Scenarios share the parent project's appliance
/// list — they only vary solar/battery/inverter assumptions — and never
/// overwrite the live project unless the user explicitly applies one.
class ProjectScenario {
  final String id;
  final String name;
  final DateTime createdAt;
  final PlanningInputs inputs;

  const ProjectScenario({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.inputs,
  });

  factory ProjectScenario.create(String name, PlanningInputs inputs) {
    return ProjectScenario(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      inputs: inputs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'inputs': inputs.toJson(),
  };

  factory ProjectScenario.fromJson(Map<String, dynamic> json) =>
      ProjectScenario(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Scenario',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        inputs: PlanningInputs.fromJson(
          json['inputs'] as Map<String, dynamic>? ?? const {},
        ),
      );
}
