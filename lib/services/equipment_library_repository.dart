import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/equipment_library_item.dart';

/// Local persistence for the user's reusable equipment library (panels,
/// batteries, inverters) — shared across all projects, separate from any
/// single project's saved data.
class EquipmentLibraryRepository {
  static const _panelsKey = 'equipment_library_panels_v1';
  static const _batteriesKey = 'equipment_library_batteries_v1';
  static const _invertersKey = 'equipment_library_inverters_v1';

  Future<List<PanelLibraryItem>> loadPanels() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_panelsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PanelLibraryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePanels(List<PanelLibraryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _panelsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<BatteryLibraryItem>> loadBatteries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_batteriesKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => BatteryLibraryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBatteries(List<BatteryLibraryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _batteriesKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<InverterLibraryItem>> loadInverters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_invertersKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => InverterLibraryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveInverters(List<InverterLibraryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _invertersKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
