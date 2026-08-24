import 'package:flutter/material.dart';

/// A short, practical explanation of one solar/electrical concept. Not
/// framed as professional engineering advice.
class InfoExplainer extends StatelessWidget {
  final String term;
  final String explanation;
  const InfoExplainer({
    super.key,
    required this.term,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $term',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 2),
            child: Text(
              explanation,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable "Learn more" card grouping several [InfoExplainer]s, reused
/// across the Loads, Solar, Battery and System screens with different
/// content for each.
class EducationCard extends StatelessWidget {
  final String title;
  final List<InfoExplainer> items;
  const EducationCard({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.help_outline, size: 20),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: items,
      ),
    );
  }
}
