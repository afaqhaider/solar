import 'package:flutter/material.dart';

/// Standing disclaimer shown at the bottom of every sizing/result screen.
/// Estimates only — never framed as a guarantee or a certified engineering
/// calculation.
class DisclaimerText extends StatelessWidget {
  final String? text;
  const DisclaimerText({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        text ??
            'These figures are estimates for planning purposes. Actual solar '
                'production and system requirements vary with weather, shading, '
                'temperature, equipment efficiency and installation conditions. '
                'Select and wire electrical equipment according to manufacturer '
                'specifications, and have final installation and electrical work '
                'verified by an appropriately qualified professional.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }
}

/// A single-line reminder used inline near a specific figure (e.g. under a
/// "Recommended" value) to reinforce that it is an estimate, not a
/// guarantee.
class InlineEstimateNote extends StatelessWidget {
  const InlineEstimateNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Estimate — not a guaranteed result.',
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
