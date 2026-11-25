import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/crypto_provider.dart';

// "● Live · 12s" pill. The provider says when prices last arrived; a
// one-second ticker stream keeps the "ago" text counting up in between.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> {
  // Prices poll every 30s, so anything older than this means updates failed
  static const _staleAfter = Duration(seconds: 90);

  final _ticker = Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );

  static String _ago(Duration age) {
    if (age.inSeconds < 60) return '${age.inSeconds}s';
    if (age.inMinutes < 60) return '${age.inMinutes}m';
    return '${age.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    final updated = context.select<CryptoProvider, DateTime?>(
      (crypto) => crypto.lastUpdated,
    );
    if (updated == null) return const SizedBox.shrink();

    return StreamBuilder<DateTime>(
      stream: _ticker,
      builder: (context, snapshot) {
        final age = (snapshot.data ?? DateTime.now()).difference(updated);
        final isStale = age > _staleAfter;
        final color = isStale ? Colors.grey : gainColor;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: darkGreen,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isStale)
                      BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${isStale ? 'Offline' : 'Live'} · ${_ago(age)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
