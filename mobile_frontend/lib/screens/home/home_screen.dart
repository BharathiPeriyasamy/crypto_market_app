import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/coin_model.dart';
import '../../providers/crypto_provider.dart';
import '../../widgets/app_navigation_bar.dart';
import '../../widgets/app_tour.dart';
import '../../widgets/coin_card.dart';
import '../../widgets/live_badge.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_message.dart';
import '../market/market_screen.dart';
import '../watchlist/watchlist_screen.dart';

// Widgets the first-run app tour points at
final _tourSearchKey = GlobalKey();
final _tourLiveKey = GlobalKey();
final _tourSortKey = GlobalKey();
final _tourCoinKey = GlobalKey<CoinCardState>();

final _tourSteps = [
  TourStep(
    target: _tourLiveKey,
    title: 'Live prices',
    text: 'Prices refresh every 30 seconds. The timer shows how long ago the '
        'last update arrived. It turns grey if updates stop.',
  ),
  TourStep(
    target: _tourSearchKey,
    title: 'Search',
    text: 'Find any coin by name or symbol.',
  ),
  TourStep(
    target: _tourSortKey,
    title: 'Sort the list',
    text: 'Order coins by market cap, price, 24h change, volume or name.',
  ),
  TourStep(
    target: _tourCoinKey,
    title: 'Coin details',
    text: 'Tap any coin to see its price chart and stats. '
        'Pull down on the list to refresh.',
  ),
  TourStep(
    target: _tourCoinKey,
    title: 'Swipe to add to Watchlist',
    text: 'Drag a coin from right to left to reveal the star, then tap it to '
        'add the coin to your Watchlist.',
    onShow: () => _tourCoinKey.currentState?.playSwipeHint(),
    onHide: () => _tourCoinKey.currentState?.stopSwipeHint(),
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Shared so other screens (like coin details) can switch the visible tab
  static final selectedTab = ValueNotifier(0);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  bool _tourChecked = false;

  int get _tabIndex => HomeScreen.selectedTab.value;

  void _onTabChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    HomeScreen.selectedTab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    HomeScreen.selectedTab.removeListener(_onTabChanged);
    super.dispose();
  }

  // Closing the search bar also clears the search text
  void _toggleSearch() {
    setState(() => _isSearching = !_isSearching);
    if (!_isSearching) context.read<CryptoProvider>().setQuery('');
  }

  // Start the tour once the coin list is on screen, so every target exists
  void _maybeStartTour(CryptoProvider crypto) {
    if (_tourChecked || crypto.status != LoadStatus.success || _tabIndex != 0) {
      return;
    }
    _tourChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppTour.showOnce(context, _tourSteps);
    });
  }

  @override
  Widget build(BuildContext context) {
    final crypto = context.watch<CryptoProvider>();
    _maybeStartTour(crypto);

    // Back from Market/Watchlist returns to the Coins tab instead of exiting
    return PopScope(
      canPop: _tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) HomeScreen.selectedTab.value = 0;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Arc.png',
            fit: BoxFit.cover,
            alignment: Alignment.topRight,
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(),
            body: _buildBody(crypto),
            bottomNavigationBar: _buildNavigationBar(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      toolbarHeight: 72,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo.png', height: 44),
          const SizedBox(width: 8),
          // Shrinks on narrow phones to make room for the live badge
          const Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Indiadits Crypto',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: _tabIndex == 0 ? 8 : 16),
          child: LiveBadge(key: _tourLiveKey),
        ),
        if (_tabIndex == 0)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              key: _tourSearchKey,
              tooltip: _isSearching ? 'Close search' : 'Search',
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              style: IconButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: offWhite,
              ),
              onPressed: _toggleSearch,
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return AppNavigationBar(
      selectedIndex: _tabIndex,
      onSelected: (index) => HomeScreen.selectedTab.value = index,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.currency_bitcoin_outlined),
          selectedIcon: Icon(Icons.currency_bitcoin),
          label: 'Coins',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Market',
        ),
        NavigationDestination(
          icon: Icon(Icons.star_border),
          selectedIcon: Icon(Icons.star),
          label: 'Watchlist',
        ),
      ],
    );
  }

  Widget _buildBody(CryptoProvider crypto) {
    switch (crypto.status) {
      case LoadStatus.loading:
        if (_tabIndex != 0) return const CoinListSkeleton();
        return const Column(
          children: [
            _SummaryCardsSkeleton(),
            Expanded(child: CoinListSkeleton()),
          ],
        );
      case LoadStatus.error:
        return StateMessage(
          icon: Icons.cloud_off,
          message: 'Could not load market data',
          onRetry: crypto.load,
        );
      case LoadStatus.success:
        return IndexedStack(
          index: _tabIndex,
          children: [
            _CoinList(showSearch: _isSearching),
            const MarketScreen(),
            const WatchlistScreen(),
          ],
        );
    }
  }
}

class _CoinList extends StatelessWidget {
  const _CoinList({required this.showSearch});

  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    final crypto = context.watch<CryptoProvider>();
    final coins = crypto.visibleCoins;

    final stats = crypto.stats;

    return Column(
      children: [
        if (showSearch) CoinSearchBar(onChanged: crypto.setQuery),
        if (stats != null) _SummaryCards(stats: stats),
        _FilterRow(crypto: crypto),
        const CoinTableHeader(),
        Expanded(
          child: coins.isEmpty
              ? const StateMessage(icon: Icons.search_off, message: 'No coins found')
              : RefreshIndicator(
                  onRefresh: crypto.load,
                  child: ListView.builder(
                    itemCount: coins.length,
                    itemBuilder: (_, index) => CoinCard(
                      key: index == 0 ? _tourCoinKey : null,
                      coin: coins[index],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.stats});

  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Global Market Cap',
                icon: Icons.public,
                value: formatMoney(stats.totalMarketCap),
                change: stats.marketCapChange24h,
                graphic: _Sparkline(color: changeColor(stats.marketCapChange24h)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: '24H Volume',
                icon: Icons.bar_chart,
                value: formatMoney(stats.totalVolume),
                graphic: const _MiniBars(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.graphic,
    this.change,
  });

  final String title;
  final IconData icon;
  final String value;
  final Widget graphic;
  final double? change;

  @override
  Widget build(BuildContext context) {
    final change = this.change;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _summaryCardDecoration,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                  Icon(icon, size: 18, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              if (change != null)
                Row(
                  children: [
                    Icon(
                      change >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: changeColor(change),
                    ),
                    Text(
                      formatPercent(change),
                      style: TextStyle(
                        color: changeColor(change),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(right: 0, bottom: 0, child: graphic),
        ],
      ),
    );
  }
}

final _summaryCardDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: borderColor),
  gradient: const LinearGradient(
    colors: [deepGreen, darkGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
);

// Placeholder for the two summary cards, sized to match the real ones
class _SummaryCardsSkeleton extends StatelessWidget {
  const _SummaryCardsSkeleton();

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: _summaryCardDecoration,
      child: const Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 90, height: 12),
              SizedBox(height: 14),
              SkeletonBox(width: 100, height: 26),
              SizedBox(height: 12),
              SkeletonBox(width: 56, height: 14),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SkeletonBox(width: 64, height: 36),
          ),
        ],
      ),
    );

    return Skeleton(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(child: card),
            const SizedBox(width: 12),
            Expanded(child: card),
          ],
        ),
      ),
    );
  }
}

// The two graphics below are decorative; the API has no history for them
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.color});

  final Color color;

  static const _values = [0.3, 0.5, 0.35, 0.6, 0.5, 0.75, 0.65, 0.9];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 36,
      child: LineChart(
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
                for (var i = 0; i < _values.length; i++)
                  FlSpot(i.toDouble(), _values[i]),
              ],
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars();

  static const _heights = [0.25, 0.35, 0.3, 0.5, 0.45, 0.7, 0.9, 1.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final height in _heights)
            Container(
              width: 5,
              height: 36 * height,
              decoration: BoxDecoration(
                color: gainColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.crypto});

  final CryptoProvider crypto;

  // (label, icon, icon color)
  static const _filters = {
    CoinFilter.all: ('All', null, null),
    CoinFilter.gainers: ('Gainers', Icons.trending_up, gainColor),
    CoinFilter.losers: ('Losers', Icons.trending_down, lossColor),  };

  // (label, sort option, ascending)
  static const _sortChoices = [
    ('Market Cap: High to Low', SortOption.marketCap, false),
    ('Price: High to Low', SortOption.price, false),
    ('Price: Low to High', SortOption.price, true),
    ('24h Change: High to Low', SortOption.change, false),
    ('Volume: High to Low', SortOption.volume, false),
    ('Name: A to Z', SortOption.name, true),
  ];

  Widget _buildChip(CoinFilter filter, (String, IconData?, Color?) data) {
    final (label, icon, iconColor) = data;
    final selected = crypto.filter == filter;
    return ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 18, color: iconColor),
      label: Text(label),
      labelStyle: const TextStyle(color: offWhite),
      selected: selected,
      onSelected: (_) => crypto.setFilter(filter),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Sort by',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final (label, option, ascending) in _sortChoices)
                ListTile(
                  title: Text(label),
                  trailing:
                      option == crypto.sortBy && ascending == crypto.ascending
                          ? const Icon(Icons.check)
                          : null,
                  onTap: () {
                    crypto.setSort(option, ascending);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  static ButtonStyle _buttonStyle(Color borderSide) => IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: darkGreen,
        side: BorderSide(color: borderSide),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in _filters.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildChip(entry.key, entry.value),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            key: _tourSortKey,
            tooltip: 'Sort by',
            icon: const Icon(Icons.swap_vert, size: 22),
            style: _buttonStyle(emeraldGreen),
            onPressed: () => _showSortSheet(context),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: crypto.activeFilterCount > 0,
            label: Text('${crypto.activeFilterCount}'),
            backgroundColor: neonGreen,
            textColor: Colors.black,
            child: IconButton(
              tooltip: 'Filters',
              icon: const Icon(Icons.tune, size: 22),
              style: _buttonStyle(
                crypto.activeFilterCount > 0 ? emeraldGreen : borderColor,
              ),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (_) => const _FilterSheet(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extra filters on top of the Gainers/Losers chips. Changes apply right away;
// the button at the bottom shows how many coins match.
class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  static const _priceRanges = {
    PriceRange.any: 'Any',
    PriceRange.under1: 'Under \$1',
    PriceRange.from1to100: '\$1 – \$100',
    PriceRange.over100: 'Over \$100',
  };

  static const _capSizes = {
    CapSize.any: 'Any',
    CapSize.large: 'Large (\$10B+)',
    CapSize.mid: 'Mid (\$1B–\$10B)',
    CapSize.small: 'Small (<\$1B)',
  };

  Widget _section<T>(
    String title,
    Map<T, String> options,
    T selected,
    ValueChanged<T> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(key: value, value: label) in options.entries)
                ChoiceChip(
                  label: Text(label),
                  labelStyle: const TextStyle(color: offWhite),
                  selected: value == selected,
                  onSelected: (_) => onSelected(value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crypto = context.watch<CryptoProvider>();
    final count = crypto.visibleCoins.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (crypto.activeFilterCount > 0)
                  TextButton(
                    onPressed: crypto.resetFilters,
                    child: const Text('Reset'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _section('Price', _priceRanges, crypto.priceRange, crypto.setPriceRange),
            _section('Market cap', _capSizes, crypto.capSize, crypto.setCapSize),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Watchlist coins only'),
              subtitle: const Text(
                'Show only coins you have starred',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              value: crypto.watchlistOnly,
              onChanged: crypto.setWatchlistOnly,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  crypto.activeFilterCount == 0
                      ? 'Show all coins ($count)'
                      : 'Show coins ($count)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
