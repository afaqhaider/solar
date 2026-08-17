import 'package:uuid/uuid.dart';

class Appliance {
  final String id;
  final String name;
  final double wattage;
  final int quantity;
  final double usageHours;

  Appliance({
    String? id,
    this.name = '',
    this.wattage = 0.0,
    this.quantity = 1,
    this.usageHours = 0.0,
  }) : id = id ?? const Uuid().v4();

  double get dailyWh => wattage * quantity * usageHours;

  Appliance copyWith({
    String? name,
    double? wattage,
    int? quantity,
    double? usageHours,
  }) {
    return Appliance(
      id: id,
      name: name ?? this.name,
      wattage: wattage ?? this.wattage,
      quantity: quantity ?? this.quantity,
      usageHours: usageHours ?? this.usageHours,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'wattage': wattage,
        'quantity': quantity,
        'usageHours': usageHours,
      };

  factory Appliance.fromJson(Map<String, dynamic> json) => Appliance(
        id: json['id'],
        name: json['name'],
        wattage: json['wattage'],
        quantity: json['quantity'],
        usageHours: json['usageHours'],
      );
}
