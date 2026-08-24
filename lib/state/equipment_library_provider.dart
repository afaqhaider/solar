import 'package:flutter/material.dart';
import '../models/equipment_library_item.dart';
import '../models/equipment_specs.dart';
import '../services/equipment_library_repository.dart';

/// The user's reusable local equipment library — "My Equipment" — shared
/// across all projects.
class EquipmentLibraryProvider extends ChangeNotifier {
  final EquipmentLibraryRepository _repository;
  EquipmentLibraryProvider({EquipmentLibraryRepository? repository})
    : _repository = repository ?? EquipmentLibraryRepository() {
    _init();
  }

  List<PanelLibraryItem> _panels = [];
  List<BatteryLibraryItem> _batteries = [];
  List<InverterLibraryItem> _inverters = [];
  bool isLoading = true;

  List<PanelLibraryItem> get panels => List.unmodifiable(_panels);
  List<BatteryLibraryItem> get batteries => List.unmodifiable(_batteries);
  List<InverterLibraryItem> get inverters => List.unmodifiable(_inverters);

  Future<void> _init() async {
    _panels = await _repository.loadPanels();
    _batteries = await _repository.loadBatteries();
    _inverters = await _repository.loadInverters();
    isLoading = false;
    notifyListeners();
  }

  Future<void> addPanel(String name, PanelSpec spec) async {
    _panels = [..._panels, PanelLibraryItem(name: name, spec: spec)];
    await _repository.savePanels(_panels);
    notifyListeners();
  }

  Future<void> updatePanel(String id, String name, PanelSpec spec) async {
    _panels = _panels
        .map(
          (p) => p.id == id
              ? PanelLibraryItem(
                  id: id,
                  name: name,
                  createdAt: p.createdAt,
                  spec: spec,
                )
              : p,
        )
        .toList();
    await _repository.savePanels(_panels);
    notifyListeners();
  }

  Future<void> duplicatePanel(String id) async {
    final idx = _panels.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _panels = [
      ..._panels,
      PanelLibraryItem(
        name: '${_panels[idx].name} (copy)',
        spec: _panels[idx].spec,
      ),
    ];
    await _repository.savePanels(_panels);
    notifyListeners();
  }

  Future<void> deletePanel(String id) async {
    _panels = _panels.where((p) => p.id != id).toList();
    await _repository.savePanels(_panels);
    notifyListeners();
  }

  Future<void> addBattery(String name, BatteryEquipmentSpec spec) async {
    _batteries = [..._batteries, BatteryLibraryItem(name: name, spec: spec)];
    await _repository.saveBatteries(_batteries);
    notifyListeners();
  }

  Future<void> updateBattery(
    String id,
    String name,
    BatteryEquipmentSpec spec,
  ) async {
    _batteries = _batteries
        .map(
          (b) => b.id == id
              ? BatteryLibraryItem(
                  id: id,
                  name: name,
                  createdAt: b.createdAt,
                  spec: spec,
                )
              : b,
        )
        .toList();
    await _repository.saveBatteries(_batteries);
    notifyListeners();
  }

  Future<void> duplicateBattery(String id) async {
    final idx = _batteries.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    _batteries = [
      ..._batteries,
      BatteryLibraryItem(
        name: '${_batteries[idx].name} (copy)',
        spec: _batteries[idx].spec,
      ),
    ];
    await _repository.saveBatteries(_batteries);
    notifyListeners();
  }

  Future<void> deleteBattery(String id) async {
    _batteries = _batteries.where((b) => b.id != id).toList();
    await _repository.saveBatteries(_batteries);
    notifyListeners();
  }

  Future<void> addInverter(String name, InverterSpec spec) async {
    _inverters = [..._inverters, InverterLibraryItem(name: name, spec: spec)];
    await _repository.saveInverters(_inverters);
    notifyListeners();
  }

  Future<void> updateInverter(String id, String name, InverterSpec spec) async {
    _inverters = _inverters
        .map(
          (i) => i.id == id
              ? InverterLibraryItem(
                  id: id,
                  name: name,
                  createdAt: i.createdAt,
                  spec: spec,
                )
              : i,
        )
        .toList();
    await _repository.saveInverters(_inverters);
    notifyListeners();
  }

  Future<void> duplicateInverter(String id) async {
    final idx = _inverters.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    _inverters = [
      ..._inverters,
      InverterLibraryItem(
        name: '${_inverters[idx].name} (copy)',
        spec: _inverters[idx].spec,
      ),
    ];
    await _repository.saveInverters(_inverters);
    notifyListeners();
  }

  Future<void> deleteInverter(String id) async {
    _inverters = _inverters.where((i) => i.id != id).toList();
    await _repository.saveInverters(_inverters);
    notifyListeners();
  }
}
