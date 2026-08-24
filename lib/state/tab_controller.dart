import 'package:flutter/foundation.dart';

/// Shared "which primary tab is active" state so quick actions (e.g. the
/// Dashboard's "Add Appliance" or "Create Project" buttons) can navigate to
/// another tab in the adaptive shell.
class SolarTabController extends ChangeNotifier {
  int index = 0;

  static const dashboard = 0;
  static const loads = 1;
  static const solar = 2;
  static const battery = 3;
  static const inverter = 4;
  static const system = 5;
  static const projects = 6;

  void goTo(int newIndex) {
    if (index == newIndex) return;
    index = newIndex;
    notifyListeners();
  }
}
