import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/crypto_provider.dart';
import '../../widgets/coin_card.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/state_message.dart';
import '../market/market_screen.dart';
import '../watchlist/watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _titles = ['Coins', 'Market', 'Watchlist'];

  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_tabIndex])),
      body: _buildBody(context.watch<CryptoProvider>()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Coins'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Market'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Watchlist'),
        ],
      ),
    );
  }

  Widget _buildBody(CryptoProvider crypto) {
    switch (crypto.status) {
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return StateMessage(
          icon: Icons.cloud_off,
          message: 'Could not load market data',
          onRetry: crypto.load,
        );
      case LoadStatus.success:
        return IndexedStack(
          index: _tabIndex,
          children: const [_CoinList(), MarketScreen(), WatchlistScreen()],
        );
    }
  }
}

class _CoinList extends StatelessWidget {
  const _CoinList();

  @override
  Widget build(BuildContext context) {
    final crypto = context.watch<CryptoProvider>();
    final coins = crypto.visibleCoins;

    return Column(
      children: [
        CoinSearchBar(onChanged: crypto.setQuery),
        _FilterRow(crypto: crypto),
        Expanded(
          child: coins.isEmpty
              ? const StateMessage(icon: Icons.search_off, message: 'No coins found')
              : RefreshIndicator(
                  onRefresh: crypto.load,
                  child: ListView.builder(
                    itemCount: coins.length,
                    itemBuilder: (_, index) => CoinCard(coin: coins[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.crypto});

  final CryptoProvider crypto;

  static const _filterLabels = {
    CoinFilter.all: 'All',
    CoinFilter.gainers: 'Gainers',
    CoinFilter.losers: 'Losers',
  };

  static const _sortLabels = {
    SortOption.marketCap: 'Market Cap',
    SortOption.price: 'Price',
    SortOption.change: '24h Change',
    SortOption.volume: 'Volume',
    SortOption.name: 'Name',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final entry in _filterLabels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: crypto.filter == entry.key,
                onSelected: (_) => crypto.setFilter(entry.key),
              ),
            ),
          const Spacer(),
          PopupMenuButton<SortOption>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            onSelected: crypto.setSort,
            itemBuilder: (_) => [
              for (final entry in _sortLabels.entries)
                PopupMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.value)),
                      if (entry.key == crypto.sortBy)
                        Icon(
                          crypto.ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
