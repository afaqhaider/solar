import 'package:flutter/material.dart';
import '../../models/system_type.dart';
import 'section_card.dart';

/// A small informational energy-flow diagram: which sources (Solar,
/// Battery, Grid) feed the Loads for the selected [SystemType]. Not
/// decorative — the arrows shown change with system type and whether a
/// battery is configured.
class EnergyFlowDiagram extends StatelessWidget {
  final SystemType systemType;
  final bool hasBattery;

  const EnergyFlowDiagram({
    super.key,
    required this.systemType,
    required this.hasBattery,
  });

  @override
  Widget build(BuildContext context) {
    final showBattery = hasBattery || systemType != SystemType.gridTied;
    final showGrid = systemType != SystemType.offGrid;

    return SectionCard(
      title: 'Energy Flow',
      icon: Icons.route_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _FlowNode(
                icon: Icons.wb_sunny,
                label: 'Solar',
                color: Color(0xFFF59E0B),
              ),
              const _FlowArrow(),
              const _FlowNode(
                icon: Icons.electrical_services,
                label: 'Loads',
                color: Color(0xFF0F4C81),
              ),
            ],
          ),
          if (showBattery) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _FlowNode(
                  icon: Icons.wb_sunny,
                  label: 'Solar',
                  color: Color(0xFFF59E0B),
                ),
                const _FlowArrow(),
                const _FlowNode(
                  icon: Icons.battery_charging_full,
                  label: 'Battery',
                  color: Color(0xFF2E7D32),
                ),
                const _FlowArrow(),
                const _FlowNode(
                  icon: Icons.electrical_services,
                  label: 'Loads',
                  color: Color(0xFF0F4C81),
                ),
              ],
            ),
          ],
          if (showGrid) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _FlowNode(
                  icon: Icons.bolt,
                  label: 'Grid',
                  color: Colors.grey,
                ),
                const _FlowArrow(),
                const _FlowNode(
                  icon: Icons.electrical_services,
                  label: 'Loads',
                  color: Color(0xFF0F4C81),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            systemType == SystemType.offGrid
                ? 'Off-grid: solar and battery are the only sources shown — no utility grid assumed.'
                : systemType == SystemType.gridTied
                ? 'Grid-tied: solar offsets grid usage; battery flow only applies if configured.'
                : 'Hybrid: solar, battery and grid can all contribute depending on conditions.',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FlowNode({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.arrow_forward, size: 16, color: Colors.grey);
  }
}
