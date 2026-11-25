import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/coin_model.dart';
import '../../providers/crypto_provider.dart';
import '../../widgets/app_navigation_bar.dart';
import '../../widgets/coin_card.dart';
import '../../widgets/price_chart.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_message.dart';
import '../home/home_screen.dart';

class CoinDetailsScreen extends StatefulWidget {
  const CoinDetailsScreen({super.key, required this.coin});

  final Coin coin;

  @override
  State<CoinDetailsScreen> createState() => _CoinDetailsScreenState();
}

class _CoinDetailsScreenState extends State<CoinDetailsScreen> {
  // ALL is five years of sample data until the backend supports full history
  static const _ranges = {
    '1D': 1,
    '1W': 7,
    '1M': 30,
    '3M': 90,
    '1Y': 365,
    'ALL': 1825,
  };

  int _days = 1;
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

  // Market and Watchlist live on the home screen, so go back there
  void _openHomeTab(int index) {
    if (index == 0) return;
    HomeScreen.selectedTab.value = index;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final coin = widget.coin;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            _buildTopBar(coin),
            const SizedBox(height: 12),
            _Header(coin: coin),
            const SizedBox(height: 16),
            _RangeSelector(
              ranges: _ranges,
              selected: _days,
              onSelected: _selectRange,
            ),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 20),
            _StatsGrid(coin: coin),
            const SizedBox(height: 4),
            _AboutBanner(coin: coin),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: 0,
        onSelected: _openHomeTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Watchlist',
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Coin coin) {
    final crypto = context.watch<CryptoProvider>();
    final isFavorite = crypto.isInWatchlist(coin.id);
    return Row(
      children: [
        _CircleButton(
          tooltip: 'Back',
          icon: Icons.arrow_back,
          onPressed: () => Navigator.maybePop(context),
        ),
        const Spacer(),
        _CircleButton(
          tooltip: isFavorite ? 'Remove from watchlist' : 'Add to watchlist',
          icon: isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite ? neonGreen : null,
          onPressed: () => crypto.toggleWatchlist(coin.id),
        ),
        const SizedBox(width: 12),
        _CircleButton(
          tooltip: 'Price alerts',
          icon: Icons.notifications_none,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Price alerts are coming soon')),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return FutureBuilder<List<ChartPoint>>(
      future: _chart,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Skeleton(
            child: SkeletonBox(height: PriceChart.height, radius: 16),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: PriceChart.height,
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
            height: PriceChart.height,
            child: StateMessage(
              icon: Icons.show_chart,
              message: 'No chart data available',
            ),
          );
        }
        return PriceChart(points: points, days: _days);
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: color, size: 20),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        backgroundColor: darkGreen,
        foregroundColor: offWhite,
        side: const BorderSide(color: borderColor),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.coin});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final change = coin.change24h;
    final color = changeColor(change);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoinLogo(coin: coin, radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: coin.name,
                  children: [
                    TextSpan(
                      text: ' (${coin.symbol.toUpperCase()})',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatPrice(coin.currentPrice),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatPercent(change),
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  const Text('(24h)', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: deepGreen,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: emeraldGreen.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.show_chart, size: 16, color: neonGreen),
                const SizedBox(width: 6),
                Text(
                  'Rank #${coin.rank}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.ranges,
    required this.selected,
    required this.onSelected,
  });

  final Map<String, int> ranges;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          for (final MapEntry(key: label, value: days) in ranges.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(days),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: days == selected
                        ? const LinearGradient(
                            colors: [emeraldGreen, neonGreen],
                          )
                        : null,
                    boxShadow: days == selected
                        ? [
                            BoxShadow(
                              color: neonGreen.withValues(alpha: 0.35),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: days == selected ? Colors.black : offWhite,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// (icon, label, value, subtitle, 24h change shown instead of the subtitle)
typedef _Stat = (IconData, String, String, String, double?);

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.coin});

  final Coin coin;

  List<_Stat> _stats() {
    final symbol = coin.symbol.toUpperCase();
    final price = coin.currentPrice;
    final maxSupply = coin.maxSupply;
    final totalSupply = coin.totalSupply;
    final volumeShare = coin.marketCap == 0
        ? 0.0
        : coin.totalVolume / coin.marketCap * 100;

    return [
      (
        Icons.monetization_on_outlined,
        'Market Cap',
        formatMoney(coin.marketCap),
        '',
        coin.change24h,
      ),
      (
        Icons.bar_chart,
        '24H Volume',
        formatMoney(coin.totalVolume),
        'Vol / MCap ${volumeShare.toStringAsFixed(2)}%',
        null,
      ),
      (
        Icons.change_circle_outlined,
        'Circulating Supply',
        '${formatCompact(coin.circulatingSupply)} $symbol',
        maxSupply == null || maxSupply == 0
            ? 'No max supply'
            : '${(coin.circulatingSupply / maxSupply * 100).toStringAsFixed(1)}%'
                ' of ${formatCompact(maxSupply)}',
        null,
      ),
      (
        Icons.pie_chart_outline,
        'Max Supply',
        maxSupply == null ? '∞' : '${formatCompact(maxSupply)} $symbol',
        totalSupply == null
            ? 'Total supply unknown'
            : 'Total ${formatCompact(totalSupply)}',
        null,
      ),
      (
        Icons.sell_outlined,
        '24H High',
        formatPrice(coin.high24h),
        '${_percentFrom(coin.high24h, price)} above price',
        null,
      ),
      (
        Icons.sell_outlined,
        '24H Low',
        formatPrice(coin.low24h),
        '${_percentFrom(price, coin.low24h)} below price',
        null,
      ),
      (
        Icons.trending_up,
        'All-Time High',
        formatPrice(coin.allTimeHigh),
        '${formatPercent((price / coin.allTimeHigh - 1) * 100)} from ATH',
        null,
      ),
      (
        Icons.trending_down,
        'All-Time Low',
        formatPrice(coin.allTimeLow),
        '${formatPercent((price / coin.allTimeLow - 1) * 100)} from ATL',
        null,
      ),
    ];
  }

  // How far `higher` is above `lower`, as a percent of the current price
  String _percentFrom(double higher, double lower) =>
      '${((higher - lower) / coin.currentPrice * 100).abs().toStringAsFixed(2)}%';

  @override
  Widget build(BuildContext context) {
    final stats = _stats();
    return Column(
      children: [
        for (var i = 0; i < stats.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _StatCard(stat: stats[i])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < stats.length
                        ? _StatCard(stat: stats[i + 1])
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final (icon, label, value, subtitle, change) = stat;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkGreen.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: deepGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: neonGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (change != null)
                  Row(
                    children: [
                      Icon(
                        change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 13,
                        color: changeColor(change),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        formatPercent(change),
                        style: TextStyle(
                          fontSize: 12,
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
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutBanner extends StatelessWidget {
  const _AboutBanner({required this.coin});

  final Coin coin;

  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About ${coin.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(coin.description),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription = coin.description.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        gradient: const LinearGradient(
          colors: [darkGreen, deepGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          CoinLogo(coin: coin, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coin.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDescription
                      ? coin.description
                      : 'Rank #${coin.rank} by market cap',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (hasDescription) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _showAbout(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: neonGreen,
                side: const BorderSide(color: neonGreen),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('About'),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
