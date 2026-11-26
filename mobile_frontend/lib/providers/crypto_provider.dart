import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/coin_model.dart';
import '../services/crypto_api_service.dart';

enum LoadStatus { loading, success, error }

enum SortOption { marketCap, price, change, volume, name }

enum CoinFilter { all, gainers, losers }

enum PriceRange { any, under1, from1to100, over100 }

// Large: $10B+, mid: $1B-$10B, small: under $1B
enum CapSize { any, large, mid, small }

class CryptoProvider extends ChangeNotifier {
  CryptoProvider(this._service) {
    // No point polling while the app is in the background
    _lifecycle = AppLifecycleListener(
      onResume: startLiveUpdates,
      onPause: stopLiveUpdates,
    );
  }

  final CryptoApiService _service;
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<(List<Coin>, MarketStats)>? _liveUpdates;

  LoadStatus status = LoadStatus.loading;
  List<Coin> coins = [];
  MarketStats? stats;

  // When prices last arrived from the backend
  DateTime? lastUpdated;

  String query = '';
  CoinFilter filter = CoinFilter.all;
  PriceRange priceRange = PriceRange.any;
  CapSize capSize = CapSize.any;
  bool watchlistOnly = false;
  SortOption sortBy = SortOption.marketCap;
  bool ascending = false;

  final Set<String> _watchlistIds = {};

  // Listens to the polling stream; prices refresh every 30 seconds
  void startLiveUpdates() {
    _liveUpdates?.cancel();
    if (coins.isEmpty) {
      status = LoadStatus.loading;
      notifyListeners();
    }
    _liveUpdates = _service.watchMarket().listen(
      _applyUpdate,
      onError: (Object _) => _markFailed(),
    );
  }

  void stopLiveUpdates() {
    _liveUpdates?.cancel();
    _liveUpdates = null;
  }

  // One-off fetch for pull-to-refresh and the retry button
  Future<void> load() async {
    // Keep showing the old list while refreshing
    if (coins.isEmpty) {
      status = LoadStatus.loading;
      notifyListeners();
    }
    try {
      _applyUpdate(
        await (_service.getCoins(), _service.getMarketStats()).wait,
      );
    } catch (_) {
      _markFailed();
    }
  }

  void _applyUpdate((List<Coin>, MarketStats) update) {
    coins = update.$1;
    stats = update.$2;
    status = LoadStatus.success;
    lastUpdated = DateTime.now();
    notifyListeners();
  }

  // A failed refresh keeps the last prices on screen
  void _markFailed() {
    if (coins.isEmpty) status = LoadStatus.error;
    notifyListeners();
  }

  Coin? coinById(String id) {
    for (final coin in coins) {
      if (coin.id == id) return coin;
    }
    return null;
  }

  @override
  void dispose() {
    _liveUpdates?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  List<Coin> get visibleCoins {
    final text = query.trim().toLowerCase();
    final result = coins.where((coin) {
      final matchesSearch = coin.name.toLowerCase().contains(text) ||
          coin.symbol.toLowerCase().contains(text);
      final matchesFilter = switch (filter) {
        CoinFilter.all => true,
        CoinFilter.gainers => coin.change24h > 0,
        CoinFilter.losers => coin.change24h < 0,
      };
      final price = coin.currentPrice;
      final matchesPrice = switch (priceRange) {
        PriceRange.any => true,
        PriceRange.under1 => price < 1,
        PriceRange.from1to100 => price >= 1 && price <= 100,
        PriceRange.over100 => price > 100,
      };
      final cap = coin.marketCap;
      final matchesCap = switch (capSize) {
        CapSize.any => true,
        CapSize.large => cap >= 10e9,
        CapSize.mid => cap >= 1e9 && cap < 10e9,
        CapSize.small => cap < 1e9,
      };
      final matchesWatchlist = !watchlistOnly || _watchlistIds.contains(coin.id);
      return matchesSearch &&
          matchesFilter &&
          matchesPrice &&
          matchesCap &&
          matchesWatchlist;
    }).toList();
    result.sort((a, b) => ascending ? _compare(a, b) : _compare(b, a));
    return result;
  }

  List<Coin> get topGainers => _byChange().take(3).toList();

  List<Coin> get topLosers => _byChange().reversed.take(3).toList();

  List<Coin> get watchlistCoins =>
      coins.where((coin) => _watchlistIds.contains(coin.id)).toList();

  bool isInWatchlist(String id) => _watchlistIds.contains(id);

  void toggleWatchlist(String id) {
    if (!_watchlistIds.remove(id)) _watchlistIds.add(id);
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setFilter(CoinFilter value) {
    filter = value;
    notifyListeners();
  }

  void setPriceRange(PriceRange value) {
    priceRange = value;
    notifyListeners();
  }

  void setCapSize(CapSize value) {
    capSize = value;
    notifyListeners();
  }

  void setWatchlistOnly(bool value) {
    watchlistOnly = value;
    notifyListeners();
  }

  // Filters from the Filters sheet (the Gainers/Losers chips are separate)
  int get activeFilterCount =>
      (priceRange != PriceRange.any ? 1 : 0) +
      (capSize != CapSize.any ? 1 : 0) +
      (watchlistOnly ? 1 : 0);

  void resetFilters() {
    priceRange = PriceRange.any;
    capSize = CapSize.any;
    watchlistOnly = false;
    notifyListeners();
  }

  void setSort(SortOption option, bool isAscending) {
    sortBy = option;
    ascending = isAscending;
    notifyListeners();
  }

  Future<List<ChartPoint>> loadChart(Coin coin, int days) =>
      _service.getChart(coin, days);

  Future<Coin> loadCoinDetail(String id) => _service.getCoinDetail(id);

  List<Coin> _byChange() =>
      [...coins]..sort((a, b) => b.change24h.compareTo(a.change24h));

  int _compare(Coin a, Coin b) => switch (sortBy) {
        SortOption.marketCap => a.marketCap.compareTo(b.marketCap),
        SortOption.price => a.currentPrice.compareTo(b.currentPrice),
        SortOption.change => a.change24h.compareTo(b.change24h),
        SortOption.volume => a.totalVolume.compareTo(b.totalVolume),
        SortOption.name => a.name.compareTo(b.name),
      };
}
