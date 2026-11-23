import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/coin_model.dart';
import '../../providers/crypto_provider.dart';
import '../../widgets/coin_card.dart';
import '../../widgets/price_chart.dart';
import '../../widgets/stat_grid.dart';
import '../../widgets/state_message.dart';

class CoinDetailsScreen extends StatefulWidget {
  const CoinDetailsScreen({super.key, required this.coin});

  final Coin coin;

  @override
  State<CoinDetailsScreen> createState() => _CoinDetailsScreenState();
}

class _CoinDetailsScreenState extends State<CoinDetailsScreen> {
  static const _ranges = {'1D': 1, '7D': 7, '30D': 30, '90D': 90, '1Y': 365};

  int _days = 7;
  late Future<List<ChartPoint>> _chart;

  @override
  void initState() {
    super.initState();
    _chart = _loadChart();
  }

  Future<List<ChartPoint>> _loadChart() =>
      context.read<CryptoProvider>().loadChart(widget.coin, _days);

  void _selectRange(int days) {
    setState(() {
      _days = days;
      _chart = _loadChart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final coin = widget.coin;
    final crypto = context.watch<CryptoProvider>();
    final isFavorite = crypto.isInWatchlist(coin.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('${coin.name} (${coin.symbol.toUpperCase()})'),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border),
            color: isFavorite ? Colors.amber : null,
            onPressed: () => crypto.toggleWatchlist(coin.id),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildHeader(coin),
          _buildRangeSelector(),
          _buildChart(),
          const SizedBox(height: 8),
          StatGrid(stats: _statsFor(coin)),
          _buildAbout(coin),
        ],
      ),
    );
  }

  Widget _buildHeader(Coin coin) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CoinLogo(coin: coin, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatPrice(coin.currentPrice),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${formatPercent(coin.change24h)} (24h)',
                  style: TextStyle(color: changeColor(coin.change24h)),
                ),
              ],
            ),
          ),
          Text('Rank #${coin.rank}'),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          for (final entry in _ranges.entries)
            ButtonSegment(value: entry.value, label: Text(entry.key)),
        ],
        selected: {_days},
        onSelectionChanged: (selection) => _selectRange(selection.first),
      ),
    );
  }

  Widget _buildChart() {
    return FutureBuilder<List<ChartPoint>>(
      future: _chart,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 240,
            child: StateMessage(
              icon: Icons.error_outline,
              message: 'Could not load the chart',
              onRetry: () => _selectRange(_days),
            ),
          );
        }
        final points = snapshot.data ?? [];
        if (points.isEmpty) {
          return const SizedBox(
            height: 240,
            child: StateMessage(
              icon: Icons.show_chart,
              message: 'No chart data available',
            ),
          );
        }
        return PriceChart(points: points);
      },
    );
  }

  Map<String, String> _statsFor(Coin coin) {
    return {
      'Market Cap': formatMoney(coin.marketCap),
      '24h Volume': formatMoney(coin.totalVolume),
      '24h High': formatPrice(coin.high24h),
      '24h Low': formatPrice(coin.low24h),
      'Circulating Supply': formatCompact(coin.circulatingSupply),
      'Total Supply': _supplyText(coin.totalSupply),
      'Max Supply': _supplyText(coin.maxSupply),
      'All-Time High': formatPrice(coin.ath),
      'All-Time Low': formatPrice(coin.atl),
    };
  }

  String _supplyText(double? supply) =>
      supply == null ? '∞' : formatCompact(supply);

  Widget _buildAbout(Coin coin) {
    if (coin.description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(coin.description),
        ],
      ),
    );
  }
}
