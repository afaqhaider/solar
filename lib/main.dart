import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/equipment_library_provider.dart';
import 'state/project_provider.dart';
import 'state/settings_provider.dart';
import 'state/tab_controller.dart';
import 'theme/solar_theme.dart';
import 'ui/app_root.dart';

void main() {
  runApp(const SolarCalculatorApp());
}

class SolarCalculatorApp extends StatelessWidget {
  const SolarCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => SolarTabController()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => EquipmentLibraryProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Solar Calculator',
            debugShowCheckedModeBanner: false,
            theme: SolarTheme.light(),
            darkTheme: SolarTheme.dark(),
            themeMode: settings.themeMode,
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}
