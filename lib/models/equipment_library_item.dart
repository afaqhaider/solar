import 'package:uuid/uuid.dart';
import 'equipment_specs.dart';

/// Named, reusable equipment templates a user has saved locally — e.g.
/// "550W Mono Panel" — that can be selected into any project.
class PanelLibraryItem {
  final String id;
  final String name;
  final DateTime createdAt;
  final PanelSpec spec;

  PanelLibraryItem({
    String? id,
    required this.name,
    DateTime? createdAt,
    required this.spec,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'spec': spec.toJson(),
  };

  factory PanelLibraryItem.fromJson(Map<String, dynamic> json) =>
      PanelLibraryItem(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Panel',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        spec: PanelSpec.fromJson(
          json['spec'] as Map<String, dynamic>? ?? const {},
        ),
      );
}

class InverterLibraryItem {
  final String id;
  final String name;
  final DateTime createdAt;
  final InverterSpec spec;

  InverterLibraryItem({
    String? id,
    required this.name,
    DateTime? createdAt,
    required this.spec,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'spec': spec.toJson(),
  };

  factory InverterLibraryItem.fromJson(Map<String, dynamic> json) =>
      InverterLibraryItem(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Inverter',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        spec: InverterSpec.fromJson(
          json['spec'] as Map<String, dynamic>? ?? const {},
        ),
      );
}

class BatteryLibraryItem {
  final String id;
  final String name;
  final DateTime createdAt;
  final BatteryEquipmentSpec spec;

  BatteryLibraryItem({
    String? id,
    required this.name,
    DateTime? createdAt,
    required this.spec,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'spec': spec.toJson(),
  };

  factory BatteryLibraryItem.fromJson(Map<String, dynamic> json) =>
      BatteryLibraryItem(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Battery',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        spec: BatteryEquipmentSpec.fromJson(
          json['spec'] as Map<String, dynamic>? ?? const {},
        ),
      );
}
