import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/coin_model.dart';
import '../../providers/crypto_provider.dart';
import '../../widgets/coin_card.dart';
import '../../widgets/stat_card.dart';
import '../home/home_screen.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  // Shows the full coin list on the Coins tab, filtered and sorted to match
  void _viewAll(CryptoProvider crypto, CoinFilter filter) {
    crypto.setFilter(filter);
    crypto.setSort(SortOption.change, filter == CoinFilter.losers);
    HomeScreen.selectedTab.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final crypto = context.watch<CryptoProvider>();
    final stats = crypto.stats;
    if (stats == null) return const SizedBox.shrink();

    final volumeShare = stats.totalMarketCap == 0
        ? 0.0
        : stats.totalVolume / stats.totalMarketCap * 100;

    return RefreshIndicator(
      onRefresh: crypto.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _MarketCapCard(stats: stats),
          const SizedBox(height: 12),
          StatCardGrid(
            children: [
              StatCard(
                icon: Icons.bar_chart,
                label: '24h Volume',
                value: formatMoney(stats.totalVolume),
                subtitle: 'Vol / MCap ${volumeShare.toStringAsFixed(2)}%',
              ),
              StatCard(
                icon: Icons.pie_chart_outline,
                label: 'BTC Dominance',
                value: '${stats.btcDominance.toStringAsFixed(1)}%',
                subtitle: 'Share of total market',
              ),
              StatCard(
                icon: Icons.diamond_outlined,
                label: 'ETH Dominance',
                value: '${stats.ethDominance.toStringAsFixed(1)}%',
                subtitle: 'Share of total market',
              ),
              StatCard(
                icon: Icons.token_outlined,
                label: 'Active Coins',
                value: _withCommas(stats.activeCoins),
                subtitle: 'Tracked cryptocurrencies',
              ),
            ],
          ),
          StatCard(
            icon: Icons.storefront_outlined,
            label: 'Markets',
            value: _withCommas(stats.markets),
            subtitle: 'Exchange trading pairs',
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Top Gainers',
            onViewAll: () => _viewAll(crypto, CoinFilter.gainers),
          ),
          _CoinTable(coins: crypto.topGainers),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Top Losers',
            onViewAll: () => _viewAll(crypto, CoinFilter.losers),
          ),
          _CoinTable(coins: crypto.topLosers),
        ],
      ),
    );
  }

  static String _withCommas(int value) => value
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

class _MarketCapCard extends StatelessWidget {
  const _MarketCapCard({required this.stats});

  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    final change = stats.marketCapChange24h;
    return Container(
      height: 130,
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        gradient: const LinearGradient(
          colors: [deepGreen, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Global Market Cap',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(stats.totalMarketCap),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChangeBadge(change: change),
                  const SizedBox(width: 8),
                  const Text(
                    '24h',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(child: _GlowLine(color: changeColor(change), rising: change >= 0)),
        ],
      ),
    );
  }
}

// Decorative trend line; the API has no market cap history yet
class _GlowLine extends StatelessWidget {
  const _GlowLine({required this.color, required this.rising});

  final Color color;
  final bool rising;

  static const _values = [
    0.20, 0.24, 0.22, 0.28, 0.26, 0.30, 0.27, 0.35, 0.33, 0.40,
    0.38, 0.45, 0.42, 0.50, 0.55, 0.52, 0.60, 0.66, 0.62, 0.72,
    0.70, 0.80, 0.76, 0.88, 0.95,
  ];

  @override
  Widget build(BuildContext context) {
    final values = rising ? _values : _values.reversed.toList();
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            color: color,
            barWidth: 2,
            shadow: Shadow(color: color.withValues(alpha: 0.8), blurRadius: 10),
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.35),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: gainColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('View All'),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// Coin rows in a rounded bordered box, matching the stat cards
class _CoinTable extends StatelessWidget {
  const _CoinTable({required this.coins});

  final List<Coin> coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: darkGreen.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const CoinTableHeader(),
          for (final coin in coins) CoinCard(key: ValueKey(coin.id), coin: coin),
        ],
      ),
    );
  }
}
