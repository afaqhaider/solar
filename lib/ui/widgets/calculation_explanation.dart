import 'package:flutter/material.dart';

/// "How this was calculated" — shows the formula conceptually, then the
/// project's actual values plugged in, so results are transparent rather
/// than a black box.
class CalculationExplanation extends StatelessWidget {
  final String title;
  final List<String> steps;
  final String result;

  const CalculationExplanation({
    super.key,
    required this.title,
    required this.steps,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(
          'How this was calculated',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.functions, size: 18),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                step,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          const Divider(height: 16),
          Text(
            result,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
