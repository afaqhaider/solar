import 'package:flutter/material.dart';
import '../../models/design_status.dart';

/// A planning indicator badge. Deliberately limited to the four
/// non-certifying statuses in [DesignStatus] — this is a planning tool,
/// not an engineering sign-off.
class DesignStatusBadge extends StatelessWidget {
  final DesignStatus status;
  const DesignStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      DesignStatus.configurationIncomplete => (
        Icons.help_outline,
        Colors.grey.shade700,
      ),
      DesignStatus.capacityShortfall => (
        Icons.warning_amber_rounded,
        Colors.orange.shade800,
      ),
      DesignStatus.meetsSelectedTarget => (
        Icons.check_circle_outline,
        Colors.green.shade700,
      ),
      DesignStatus.additionalReserveAvailable => (
        Icons.add_circle_outline,
        Colors.blue.shade700,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
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
