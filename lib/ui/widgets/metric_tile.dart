import 'package:flutter/material.dart';

/// A compact label/value/sub-label metric, used across the dashboard and
/// result summaries.
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData? icon;
  final Color? valueColor;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (sub != null)
          Text(sub!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

/// A larger dashboard tile with an icon, headline value and label, used in
/// the responsive dashboard grid.
class DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color? accent;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    required this.icon,
    this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub!,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
