import 'package:flutter/material.dart';
import '../../core/units.dart';
import '../../models/results.dart';
import '../../theme/solar_theme.dart';

/// Simple horizontal bar breakdown of which appliances consume the most
/// energy. Built with plain Flutter widgets — no charting dependency.
class LoadBreakdownChart extends StatelessWidget {
  final List<LoadContribution> breakdown;
  final int maxItems;

  const LoadBreakdownChart({
    super.key,
    required this.breakdown,
    this.maxItems = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No enabled appliances yet.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }
    final top = breakdown.take(maxItems).toList();
    final maxShare = top.first.shareOfTotal <= 0 ? 1.0 : top.first.shareOfTotal;

    return Column(
      children: [
        for (int i = 0; i < top.length; i++) ...[
          _BreakdownRow(
            contribution: top[i],
            color: EnergyPalette.forIndex(i),
            relativeWidth: maxShare > 0 ? top[i].shareOfTotal / maxShare : 0,
          ),
          if (i != top.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final LoadContribution contribution;
  final Color color;
  final double relativeWidth;

  const _BreakdownRow({
    required this.contribution,
    required this.color,
    required this.relativeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                contribution.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${Units.formatWh(contribution.averageDailyWh)}/day · ${(contribution.shareOfTotal * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: constraints.maxWidth * relativeWidth.clamp(0.02, 1.0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
