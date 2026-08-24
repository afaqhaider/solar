import 'package:flutter/material.dart';

class _HelpTopic {
  final String title;
  final String body;
  const _HelpTopic(this.title, this.body);
}

const _topics = [
  _HelpTopic(
    'Getting Started',
    'Create a project, then add appliances in Loads. The app calculates your load profile, then estimates solar, battery and inverter requirements from it.',
  ),
  _HelpTopic(
    'Building a Load Profile',
    'Add each appliance with its wattage, quantity and daily usage hours. Presets are editable examples, not guaranteed specs.',
  ),
  _HelpTopic(
    'Understanding Watts and Watt-Hours',
    'Watts (W) is the instantaneous draw while running. Watt-hours (Wh) is energy over time: watts × hours. Daily energy is what your solar system must replace each day.',
  ),
  _HelpTopic(
    'Peak Sun Hours',
    'Not daylight hours — the equivalent hours of maximum-intensity sunlight your location receives per day, used to size the solar array.',
  ),
  _HelpTopic(
    'Solar Array Sizing',
    'Required array = daily energy ÷ peak sun hours ÷ system efficiency. A design reserve adds margin on top of that minimum.',
  ),
  _HelpTopic(
    'Battery Storage',
    'Battery sizing targets your essential (backup-required) load for a chosen backup duration, accounting for depth of discharge and round-trip efficiency.',
  ),
  _HelpTopic(
    'Battery Series & Parallel',
    'Series wiring adds battery voltages together (Ah unchanged). Parallel wiring adds battery Ah together (voltage unchanged).',
  ),
  _HelpTopic(
    'Essential Loads',
    'Mark appliances "Backup required" (fridge, lights, router) to build an Essential Load Profile used for battery and inverter backup sizing — instead of your entire connected load.',
  ),
  _HelpTopic(
    'Inverter Sizing',
    'The inverter should comfortably cover running load plus headroom, and clear a reasonable surge estimate for motor-driven appliances.',
  ),
  _HelpTopic(
    'Surge Loads',
    'Motor-driven appliances (compressors, pumps, A/C) briefly draw more power at startup than while running. Standard mode assumes one motor starts at a time; Conservative assumes overlap.',
  ),
  _HelpTopic(
    'Grid-Tied Systems',
    'Primarily solar generation with utility grid availability. Battery storage is optional.',
  ),
  _HelpTopic(
    'Hybrid Systems',
    'Solar generation with battery storage and the utility grid as a backstop.',
  ),
  _HelpTopic(
    'Off-Grid Systems',
    'Solar generation with battery storage and no assumption of continuous utility grid support — reserve and autonomy matter more here.',
  ),
  _HelpTopic(
    'Equipment Specifications',
    'Optionally define the panel/battery/inverter specs you\'re considering in Equipment, to unlock compatibility checks and a basic string planner.',
  ),
  _HelpTopic(
    'PV Strings',
    'A string planner combines panels-per-string and parallel strings into string voltage, current and array power. Temperature effects on Voc are not modeled — verify final design against equipment specs.',
  ),
  _HelpTopic(
    'Understanding Reports',
    'The planning report is generated from your project\'s actual calculated data, never a UI screenshot, and always includes the planning disclaimer.',
  ),
  _HelpTopic(
    'Calculation Limitations',
    'All figures are planning estimates only. Actual solar production, battery runtime and system requirements vary with weather, shading, temperature, equipment condition and installation. This is not a certified engineering calculation.',
  ),
];

/// Offline help content, organized around the app's actual functionality.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _topics.length,
        itemBuilder: (context, i) {
          final t = _topics[i];
          return Card(
            child: ExpansionTile(
              title: Text(
                t.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.body,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
