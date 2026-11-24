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
          const CoinTableHeader(),
          for (final coin in crypto.topGainers) CoinCard(coin: coin),
          _SectionTitle('Top Losers'),
          const CoinTableHeader(),
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
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        gradient: const LinearGradient(
          colors: [deepGreen, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Global Market Cap', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            formatMoney(stats.totalMarketCap),
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChangeBadge(change: stats.marketCapChange24h),
              const SizedBox(width: 8),
              Text('24h', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
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
