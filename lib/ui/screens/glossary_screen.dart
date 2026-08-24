import 'package:flutter/material.dart';

const _terms = <String, String>{
  'W (Watt)': 'Unit of instantaneous electrical power.',
  'kW (Kilowatt)': '1,000 watts.',
  'Wh (Watt-hour)': 'Unit of energy: one watt sustained for one hour.',
  'kWh (Kilowatt-hour)':
      '1,000 watt-hours; the usual unit for daily/monthly energy.',
  'Ah (Amp-hour)': 'A battery capacity rating: current sustained for one hour.',
  'V (Volt)': 'Unit of electrical potential difference.',
  'A (Amp)': 'Unit of electrical current.',
  'Voc':
      'Open-circuit voltage of a solar panel or string — the voltage with no load connected.',
  'Vmp':
      'Voltage at a panel\'s maximum power point under standard test conditions.',
  'Isc': 'Short-circuit current of a solar panel.',
  'Imp': 'Current at a panel\'s maximum power point.',
  'DoD (Depth of Discharge)':
      'The percentage of a battery\'s rated capacity considered safely usable.',
  'MPPT':
      'Maximum Power Point Tracking — the charge-controller/inverter technique that keeps a solar array operating near its most efficient voltage/current point.',
  'Peak Sun Hours':
      'Equivalent hours per day of maximum-intensity sunlight at a location — not the same as daylight hours.',
  'Inverter':
      'Converts DC power (from panels/battery) to AC power for household use.',
  'Solar Array':
      'The complete set of solar panels working together as one generating unit.',
  'Battery Bank':
      'One or more batteries wired in series and/or parallel to form a single storage unit.',
  'Surge Load':
      'A brief, higher-than-running power draw some motor-driven appliances need at startup.',
};

/// A compact, technically accurate solar/electrical glossary.
class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = _terms.entries.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Glossary')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (context, i) => const Divider(height: 20),
        itemBuilder: (context, i) {
          final e = entries[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.key,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                e.value,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          );
        },
      ),
    );
  }
}
