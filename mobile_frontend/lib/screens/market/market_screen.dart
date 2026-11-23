import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/coin_model.dart';
import '../../providers/crypto_provider.dart';
import '../../widgets/coin_card.dart';
import '../../widgets/stat_grid.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final crypto = context.watch<CryptoProvider>();
    final stats = crypto.stats;
    if (stats == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: crypto.load,
      child: ListView(
        children: [
          _MarketCapCard(stats: stats),
          StatGrid(stats: {
            '24h Volume': formatMoney(stats.totalVolume),
            'BTC Dominance': '${stats.btcDominance.toStringAsFixed(1)}%',
            'ETH Dominance': '${stats.ethDominance.toStringAsFixed(1)}%',
            'Active Coins': stats.activeCoins.toString(),
            'Markets': stats.markets.toString(),
          }),
          _SectionTitle('Top Gainers'),
          for (final coin in crypto.topGainers) CoinCard(coin: coin),
          _SectionTitle('Top Losers'),
          for (final coin in crypto.topLosers) CoinCard(coin: coin),
        ],
      ),
    );
  }
}

class _MarketCapCard extends StatelessWidget {
  const _MarketCapCard({required this.stats});

  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Global Market Cap', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              formatMoney(stats.totalMarketCap),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '${formatPercent(stats.marketCapChange24h)} (24h)',
              style: TextStyle(color: changeColor(stats.marketCapChange24h)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
