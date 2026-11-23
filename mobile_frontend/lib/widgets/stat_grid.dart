import 'package:flutter/material.dart';

// Two-column grid of label/value tiles
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.stats});

  final Map<String, String> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final entry in stats.entries)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    entry.value,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
