import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/coin_model.dart';
import '../../providers/crypto_provider.dart';
import '../../widgets/app_navigation_bar.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/coin_card.dart';
import '../../widgets/price_chart.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/state_message.dart';
import '../home/home_screen.dart';

class CoinDetailsScreen extends StatefulWidget {
  const CoinDetailsScreen({super.key, required this.coin});

  final Coin coin;

  @override
  State<CoinDetailsScreen> createState() => _CoinDetailsScreenState();
}

class _CoinDetailsScreenState extends State<CoinDetailsScreen> {
  // 0 = ALL, the coin's full history
  static const _ranges = {
    '1D': 1,
    '1W': 7,
    '1M': 30,
    '3M': 90,
    '1Y': 365,
    'ALL': 0,
  };

  int _days = 1;
  late Future<List<ChartPoint>> _chart;

  // The list data has no description; swap in the full details once loaded
  late Coin _coin = widget.coin;

  @override
  void initState() {
    super.initState();
    _chart = _loadChart();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail =
          await context.read<CryptoProvider>().loadCoinDetail(widget.coin.id);
      if (mounted) setState(() => _coin = detail);
    } catch (_) {
      // Keep showing the list data; only the description is missing
    }
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
    // Prices come live from the provider; the description from the detail fetch
    final coin = context.select<CryptoProvider, Coin?>(
          (crypto) => crypto.coinById(widget.coin.id),
        ) ??
        _coin;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            _buildTopBar(coin),
            const SizedBox(height: 8),
            _Header(coin: coin),
            const SizedBox(height: 12),
            _RangeSelector(
              ranges: _ranges,
              selected: _days,
              onSelected: _selectRange,
            ),
            const SizedBox(height: 12),
            _buildChart(),
            const SizedBox(height: 20),
            _StatsGrid(coin: coin),
            const SizedBox(height: 4),
            _AboutBanner(coin: coin, description: _coin.description),
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
          color: isFavorite ? starColor : null,
          onPressed: () {
            crypto.toggleWatchlist(coin.id);
            showWatchlistSnackBar(
              context,
              coinName: coin.name,
              added: !isFavorite,
              onUndo: () => crypto.toggleWatchlist(coin.id),
            );
          },
        ),
        const SizedBox(width: 8),
        _CircleButton(
          tooltip: 'Price alerts',
          icon: Icons.notifications_none,
          onPressed: () => showComingSoonSnackBar(context, 'Price alerts'),
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
        return PriceChart(points: points);
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
      icon: Icon(icon, color: color, size: 18),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        fixedSize: const Size(34, 34),
        padding: EdgeInsets.zero,
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
        CoinLogo(coin: coin, radius: 18),
        const SizedBox(width: 10),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatPrice(coin.currentPrice),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatPercent(change),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '(24h)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: deepGreen,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: gainColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.show_chart, size: 14, color: gainColor),
                const SizedBox(width: 4),
                Text(
                  'Rank #${coin.rank}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(24),
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
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: days == selected ? gainColor : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
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
    return StatCardGrid(
      children: [
        for (final (icon, label, value, subtitle, change) in _stats())
          StatCard(
            icon: icon,
            label: label,
            value: value,
            subtitle: subtitle,
            change: change,
          ),
      ],
    );
  }
}

class _AboutBanner extends StatelessWidget {
  const _AboutBanner({required this.coin, required this.description});

  final Coin coin;
  final String description;

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
              Text(description),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription = description.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          gradient: const LinearGradient(
            colors: [darkGreen, deepGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: InkWell(
          // Tapping the banner opens the full description
          onTap: hasDescription ? () => _showAbout(context) : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CoinLogo(coin: coin, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coin.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasDescription
                            ? description
                            : 'Rank #${coin.rank} by market cap',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => showComingSoonSnackBar(context, 'Trading'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: gainColor,
                    side: const BorderSide(color: gainColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Trade Now'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
