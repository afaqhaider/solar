import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/appliance.dart';
import '../models/solar_result.dart';
import 'solar_calculator.dart';

class SolarProvider extends ChangeNotifier {
  List<Appliance> _appliances = [];
  String peakSunHours = "5";
  String efficiency = "80";
  String panelWattage = "550";
  String backupHours = "0";
  String batteryVoltage = "48";
  String batteryAh = "100";
  String batteryDoD = "80";

  SolarResult? result;
  Map<String, String?> errors = {};

  List<Appliance> get appliances => _appliances;

  SolarProvider() {
    _loadState();
  }

  void addAppliance(Appliance appliance) {
    _appliances.add(appliance);
    calculate();
    _saveState();
    notifyListeners();
  }

  void updateAppliance(Appliance updated) {
    final index = _appliances.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _appliances[index] = updated;
      calculate();
      _saveState();
      notifyListeners();
    }
  }

  void deleteAppliance(String id) {
    _appliances.removeWhere((a) => a.id == id);
    calculate();
    _saveState();
    notifyListeners();
  }

  void updateField(String field, String value) {
    switch (field) {
      case "peakSunHours": peakSunHours = value; break;
      case "efficiency": efficiency = value; break;
      case "panelWattage": panelWattage = value; break;
      case "backupHours": backupHours = value; break;
      case "batteryVoltage": batteryVoltage = value; break;
      case "batteryAh": batteryAh = value; break;
      case "batteryDoD": batteryDoD = value; break;
    }
    calculate();
    _saveState();
    notifyListeners();
  }

  void reset() {
    _appliances = [];
    peakSunHours = "5";
    efficiency = "80";
    panelWattage = "550";
    backupHours = "0";
    batteryVoltage = "48";
    batteryAh = "100";
    batteryDoD = "80";
    result = null;
    errors = {};
    _saveState();
    notifyListeners();
  }

  void calculate() {
    final pSun = double.tryParse(peakSunHours) ?? -1.0;
    final eff = double.tryParse(efficiency) ?? -1.0;
    final pWatt = double.tryParse(panelWattage) ?? -1.0;
    final bHours = double.tryParse(backupHours) ?? -1.0;
    final bVolt = double.tryParse(batteryVoltage) ?? -1.0;
    final bAh = double.tryParse(batteryAh) ?? -1.0;
    final bDoD = double.tryParse(batteryDoD) ?? -1.0;

    errors = {};
    if (peakSunHours.isNotEmpty && pSun <= 0) errors["peakSunHours"] = "Must be > 0";
    if (efficiency.isNotEmpty && (eff <= 0 || eff > 100)) errors["efficiency"] = "1-100%";
    if (panelWattage.isNotEmpty && pWatt <= 0) errors["panelWattage"] = "Must be > 0";
    if (backupHours.isNotEmpty && bHours < 0) errors["backupHours"] = "Must be >= 0";
    if (batteryVoltage.isNotEmpty && bVolt <= 0) errors["batteryVoltage"] = "Must be > 0";
    if (batteryAh.isNotEmpty && bAh <= 0) errors["batteryAh"] = "Must be > 0";
    if (batteryDoD.isNotEmpty && (bDoD <= 0 || bDoD > 100)) errors["batteryDoD"] = "1-100%";

    if (errors.isEmpty && pSun > 0 && eff > 0) {
      result = SolarCalculator.calculate(
        appliances: _appliances,
        peakSunHours: pSun,
        efficiency: eff,
        panelWattage: pWatt,
        backupHours: bHours,
        batteryVoltage: bVolt,
        batteryAh: bAh,
        batteryDoD: bDoD,
      );
    } else {
      result = null;
    }
    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final appliancesJson = jsonEncode(_appliances.map((a) => a.toJson()).toList());
    await prefs.setString('appliances', appliancesJson);
    await prefs.setString('peakSunHours', peakSunHours);
    await prefs.setString('efficiency', efficiency);
    await prefs.setString('panelWattage', panelWattage);
    await prefs.setString('backupHours', backupHours);
    await prefs.setString('batteryVoltage', batteryVoltage);
    await prefs.setString('batteryAh', batteryAh);
    await prefs.setString('batteryDoD', batteryDoD);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final appliancesStr = prefs.getString('appliances') ?? '[]';
    final List<dynamic> decoded = jsonDecode(appliancesStr);
    _appliances = decoded.map((item) => Appliance.fromJson(item)).toList();
    
    peakSunHours = prefs.getString('peakSunHours') ?? "5";
    efficiency = prefs.getString('efficiency') ?? "80";
    panelWattage = prefs.getString('panelWattage') ?? "550";
    backupHours = prefs.getString('backupHours') ?? "0";
    batteryVoltage = prefs.getString('batteryVoltage') ?? "48";
    batteryAh = prefs.getString('batteryAh') ?? "100";
    batteryDoD = prefs.getString('batteryDoD') ?? "80";
    
    calculate();
  }

  void shareResults() {
    if (result == null) return;
    final res = result!;
    
    String text = "Solar System Estimate\n\n"
        "Energy:\n"
        "- Connected Load: ${formatWatts(res.totalConnectedLoadW)}\n"
        "- Daily Consumption: ${formatKWh(res.dailyEnergyWh)}\n\n"
        "Solar:\n"
        "- Required Array: ${formatWatts(res.requiredSolarArrayW)}\n"
        "- Panels: ${res.panelCount} x ${res.panelWattage.toInt()}W\n"
        "- Installed Capacity: ${formatWatts(res.installedSolarCapacityW)}\n\n"
        "Inverter:\n"
        "- Recommended: ${formatWatts(res.minInverterCapacityW)}\n";

    if (res.batteryBackupEnabled) {
      text += "\nBattery:\n"
          "- Backup Energy: ${formatKWh(res.backupEnergyWh)}\n"
          "- Specification: ${res.batteryVoltage.toInt()}V ${res.batteryAh.toInt()}Ah\n"
          "- Estimated Quantity: ${res.batteryCount}";
    }

    Share.share(text, subject: 'Solar System Estimate');
  }

  String formatWatts(double w) => w >= 1000 ? "${(w / 1000).toStringAsFixed(2)} kW" : "${w.toStringAsFixed(0)} W";
  String formatKWh(double wh) => "${(wh / 1000).toStringAsFixed(2)} kWh";
}
