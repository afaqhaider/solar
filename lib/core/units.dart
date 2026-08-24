/// Centralized unit formatting and conversion helpers for the solar planner.
///
/// All energy/power/electrical unit math and display formatting should go
/// through this class so units are never silently mixed or duplicated
/// across screens.
class Units {
  Units._();

  // ---- Power ----
  static double wToKw(double watts) => watts / 1000.0;
  static double kwToW(double kilowatts) => kilowatts * 1000.0;

  // ---- Energy ----
  static double whToKwh(double wh) => wh / 1000.0;
  static double kwhToWh(double kwh) => kwh * 1000.0;

  // ---- Battery ----
  /// Usable energy (Wh) stored in a battery bank given nameplate Ah, volts
  /// and usable depth-of-discharge percentage (0-100).
  static double ahToUsableWh(double ah, double volts, double dodPercent) {
    return ah * volts * (dodPercent / 100.0);
  }

  // ---- Formatting ----
  static String formatWatts(double w) {
    if (w.abs() >= 1000) return '${wToKw(w).toStringAsFixed(2)} kW';
    return '${w.toStringAsFixed(0)} W';
  }

  static String formatWh(double wh) {
    if (wh.abs() >= 1000) return '${whToKwh(wh).toStringAsFixed(2)} kWh';
    return '${wh.toStringAsFixed(0)} Wh';
  }

  static String formatKwh(double kwh) => '${kwh.toStringAsFixed(2)} kWh';

  static String formatAh(double ah) => '${ah.toStringAsFixed(0)} Ah';

  static String formatVoltage(double v) => '${v.toStringAsFixed(0)} V';

  static String formatCurrent(double a) => '${a.toStringAsFixed(1)} A';

  static String formatPercent(double p) => '${p.toStringAsFixed(0)}%';
}
