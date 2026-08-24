import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for app-wide (non-project) settings.
class SettingsRepository {
  static const _themeModeKey =
      'settings_theme_mode_v1'; // 'system' | 'light' | 'dark'
  static const _onboardingSeenKey = 'settings_onboarding_seen_v1';
  static const _defaultEfficiencyKey = 'settings_default_efficiency_v1';
  static const _defaultReserveKey = 'settings_default_reserve_v1';
  static const _defaultHeadroomKey = 'settings_default_headroom_v1';
  static const _defaultCurrencyKey = 'settings_default_currency_v1';

  Future<String?> loadThemeMode() async =>
      (await SharedPreferences.getInstance()).getString(_themeModeKey);
  Future<void> saveThemeMode(String mode) async =>
      (await SharedPreferences.getInstance()).setString(_themeModeKey, mode);

  Future<bool> loadOnboardingSeen() async =>
      (await SharedPreferences.getInstance()).getBool(_onboardingSeenKey) ??
      false;
  Future<void> saveOnboardingSeen(bool seen) async =>
      (await SharedPreferences.getInstance()).setBool(_onboardingSeenKey, seen);

  Future<double?> loadDefaultEfficiency() async =>
      (await SharedPreferences.getInstance()).getDouble(_defaultEfficiencyKey);
  Future<void> saveDefaultEfficiency(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(
        _defaultEfficiencyKey,
        v,
      );

  Future<double?> loadDefaultReserve() async =>
      (await SharedPreferences.getInstance()).getDouble(_defaultReserveKey);
  Future<void> saveDefaultReserve(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_defaultReserveKey, v);

  Future<double?> loadDefaultHeadroom() async =>
      (await SharedPreferences.getInstance()).getDouble(_defaultHeadroomKey);
  Future<void> saveDefaultHeadroom(double v) async =>
      (await SharedPreferences.getInstance()).setDouble(_defaultHeadroomKey, v);

  Future<String?> loadDefaultCurrency() async =>
      (await SharedPreferences.getInstance()).getString(_defaultCurrencyKey);
  Future<void> saveDefaultCurrency(String v) async =>
      (await SharedPreferences.getInstance()).setString(_defaultCurrencyKey, v);
}
