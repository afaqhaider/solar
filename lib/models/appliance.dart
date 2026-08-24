import 'package:uuid/uuid.dart';

/// A single load (appliance) in a project's load profile.
///
/// [wattage] is the running/nameplate power draw. [surgeWattage] is an
/// optional, higher instantaneous draw some motor-driven appliances need at
/// startup (e.g. compressors, pumps) — used only for peak/surge load and
/// inverter sizing, never for daily energy totals.
class Appliance {
  final String id;
  final String name;
  final String category;
  final double wattage;
  final int quantity;
  final double usageHours;

  /// Days per week the appliance is actually used. Defaults to 7 (daily).
  final double daysPerWeek;

  /// Optional startup/surge wattage (per unit). Null/0 means "not applicable".
  final double? surgeWattage;

  final bool enabled;

  /// Whether this appliance is part of the Essential Load Profile used for
  /// battery and inverter backup planning (e.g. fridge, lights, router —
  /// as opposed to loads like an A/C that may be dropped during an outage).
  final bool backupRequired;

  Appliance({
    String? id,
    this.name = '',
    this.category = 'Custom',
    this.wattage = 0.0,
    this.quantity = 1,
    this.usageHours = 0.0,
    this.daysPerWeek = 7,
    this.surgeWattage,
    this.enabled = true,
    this.backupRequired = false,
  }) : id = id ?? const Uuid().v4();

  /// Energy consumed on a day the appliance is actually used.
  double get dailyWh => wattage * quantity * usageHours;

  /// Energy consumed per week, accounting for [daysPerWeek].
  double get weeklyWh => dailyWh * daysPerWeek;

  /// Average energy per calendar day, spread across the whole week.
  /// This is the figure used for daily/monthly consumption totals so a
  /// appliance used 3x/week doesn't get counted as if used every day.
  double get averageDailyWh => weeklyWh / 7.0;

  double get averageMonthlyKWh => averageDailyWh * 30.0 / 1000.0;

  /// Nameplate/running contribution to connected load (W).
  double get connectedLoadContributionW => wattage * quantity;

  /// Extra instantaneous draw above running load this appliance may add
  /// at startup, per the full quantity (0 if no surge specified).
  double get surgeContributionW {
    if (surgeWattage == null || surgeWattage! <= wattage) return 0.0;
    return (surgeWattage! - wattage) * quantity;
  }

  Appliance copyWith({
    String? name,
    String? category,
    double? wattage,
    int? quantity,
    double? usageHours,
    double? daysPerWeek,
    double? surgeWattage,
    bool clearSurge = false,
    bool? enabled,
    bool? backupRequired,
  }) {
    return Appliance(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      wattage: wattage ?? this.wattage,
      quantity: quantity ?? this.quantity,
      usageHours: usageHours ?? this.usageHours,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      surgeWattage: clearSurge ? null : (surgeWattage ?? this.surgeWattage),
      enabled: enabled ?? this.enabled,
      backupRequired: backupRequired ?? this.backupRequired,
    );
  }

  /// Returns a copy with a freshly generated id, used for "duplicate".
  Appliance duplicated() => Appliance(
    name: '$name (copy)',
    category: category,
    wattage: wattage,
    quantity: quantity,
    usageHours: usageHours,
    daysPerWeek: daysPerWeek,
    surgeWattage: surgeWattage,
    enabled: enabled,
    backupRequired: backupRequired,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'wattage': wattage,
    'quantity': quantity,
    'usageHours': usageHours,
    'daysPerWeek': daysPerWeek,
    'surgeWattage': surgeWattage,
    'enabled': enabled,
    'backupRequired': backupRequired,
  };

  factory Appliance.fromJson(Map<String, dynamic> json) => Appliance(
    id: json['id'] as String?,
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? 'Custom',
    wattage: (json['wattage'] as num?)?.toDouble() ?? 0.0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    usageHours: (json['usageHours'] as num?)?.toDouble() ?? 0.0,
    daysPerWeek: (json['daysPerWeek'] as num?)?.toDouble() ?? 7.0,
    surgeWattage: (json['surgeWattage'] as num?)?.toDouble(),
    enabled: json['enabled'] as bool? ?? true,
    // Missing key on projects saved by earlier app versions defaults to
    // false, which is a safe, non-destructive migration.
    backupRequired: json['backupRequired'] as bool? ?? false,
  );
}
