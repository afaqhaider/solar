import 'package:flutter/material.dart';

/// Solar/energy visual identity: a sun-amber primary with a deep energy-blue
/// secondary, used consistently across the dashboard, sizing screens and
/// charts instead of a generic accent-color swap.
class SolarTheme {
  SolarTheme._();

  static const Color sunAmber = Color(0xFFF59E0B);
  static const Color energyBlue = Color(0xFF0F4C81);
  static const Color leafGreen = Color(0xFF2E7D32);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: sunAmber,
      brightness: brightness,
      secondary: energyBlue,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Semantic energy colors used for load-breakdown charts, independent of
/// the app's brand color, so appliance categories stay visually distinct.
class EnergyPalette {
  EnergyPalette._();

  static const List<Color> categorySeries = [
    Color(0xFFF59E0B), // amber
    Color(0xFF0F4C81), // energy blue
    Color(0xFF2E7D32), // green
    Color(0xFF8E24AA), // purple
    Color(0xFFD84315), // deep orange
    Color(0xFF00838F), // teal
    Color(0xFF6D4C41), // brown
  ];

  static Color forIndex(int i) => categorySeries[i % categorySeries.length];
}
