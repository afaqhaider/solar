import 'package:flutter/material.dart';
import '../services/settings_repository.dart';

/// App-wide (non-project) preferences: appearance, first-launch onboarding,
/// and convenience defaults applied to newly created projects.
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;
  SettingsProvider({SettingsRepository? repository})
    : _repository = repository ?? SettingsRepository() {
    _init();
  }

  bool isLoading = true;
  ThemeMode themeMode = ThemeMode.system;
  bool onboardingSeen = false;

  double? defaultEfficiencyPercent;
  double? defaultReservePercent;
  double? defaultHeadroomPercent;
  String? defaultCurrencyLabel;

  Future<void> _init() async {
    final mode = await _repository.loadThemeMode();
    themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    onboardingSeen = await _repository.loadOnboardingSeen();
    defaultEfficiencyPercent = await _repository.loadDefaultEfficiency();
    defaultReservePercent = await _repository.loadDefaultReserve();
    defaultHeadroomPercent = await _repository.loadDefaultHeadroom();
    defaultCurrencyLabel = await _repository.loadDefaultCurrency();
    isLoading = false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _repository.saveThemeMode(switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    notifyListeners();
  }

  Future<void> setOnboardingSeen(bool seen) async {
    onboardingSeen = seen;
    await _repository.saveOnboardingSeen(seen);
    notifyListeners();
  }

  Future<void> setDefaultEfficiency(double? v) async {
    defaultEfficiencyPercent = v;
    if (v != null) await _repository.saveDefaultEfficiency(v);
    notifyListeners();
  }

  Future<void> setDefaultReserve(double? v) async {
    defaultReservePercent = v;
    if (v != null) await _repository.saveDefaultReserve(v);
    notifyListeners();
  }

  Future<void> setDefaultHeadroom(double? v) async {
    defaultHeadroomPercent = v;
    if (v != null) await _repository.saveDefaultHeadroom(v);
    notifyListeners();
  }

  Future<void> setDefaultCurrency(String? v) async {
    defaultCurrencyLabel = v;
    if (v != null) await _repository.saveDefaultCurrency(v);
    notifyListeners();
  }
}
