import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_provider.dart';
import 'app_shell.dart';
import 'screens/onboarding_screen.dart';

/// Decides whether to show first-launch Onboarding or the main app shell.
/// Onboarding is shown once (tracked in [SettingsProvider]) and can be
/// reopened later from Settings/Help.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        if (settings.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!settings.onboardingSeen) {
          return OnboardingScreen(
            onFinished: () => settings.setOnboardingSeen(true),
          );
        }
        return const AppShell();
      },
    );
  }
}
