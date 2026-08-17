import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'logic/solar_provider.dart';
import 'ui/solar_calculator_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SolarProvider(),
      child: const SolarCalculatorApp(),
    ),
  );
}

class SolarCalculatorApp extends StatelessWidget {
  const SolarCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SolarCalculatorScreen(),
    );
  }
}
