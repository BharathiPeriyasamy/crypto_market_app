import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';

// Compact stat tile: icon badge, label, value and either a 24h change or a
// grey subtitle underneath. Optional trailing widget (e.g. a chevron).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle = '',
    this.change,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final double? change;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final change = this.change;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: darkGreen.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: deepGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: gainColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (change != null)
                        Row(
                          children: [
                            Icon(
                              change >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 11,
                              color: changeColor(change),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              formatPercent(change),
                              style: TextStyle(
                                fontSize: 10,
                                color: changeColor(change),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (trailing case final trailing?)
                  Align(alignment: Alignment.center, child: trailing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Lays cards out two per row, each row as tall as its tallest card
class StatCardGrid extends StatelessWidget {
  const StatCardGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: children[i]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: i + 1 < children.length
                        ? children[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
