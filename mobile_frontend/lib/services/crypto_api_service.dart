import 'dart:math';

import '../models/coin_model.dart';

// Sample data for building the UI. Replace the bodies with backend calls later.
class CryptoApiService {
  Future<List<Coin>> getCoins() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _sampleCoins;
  }

  Future<MarketStats> getMarketStats() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final totalCap = _sampleCoins.fold(0.0, (sum, c) => sum + c.marketCap);
    final weightedChange = _sampleCoins.fold(
      0.0,
      (sum, c) => sum + c.change24h * c.marketCap,
    );
    return MarketStats(
      totalMarketCap: totalCap,
      totalVolume: _sampleCoins.fold(0.0, (sum, c) => sum + c.totalVolume),
      marketCapChange24h: weightedChange / totalCap,
      btcDominance: _sampleCoins[0].marketCap / totalCap * 100,
      ethDominance: _sampleCoins[1].marketCap / totalCap * 100,
      activeCoins: 14000,
      markets: 1100,
    );
  }

  Future<List<ChartPoint>> getChart(Coin coin, int days) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final random = Random(coin.id.hashCode + days);
    final count = days <= 1 ? 96 : min(days * 24, 200);
    final step = Duration(minutes: days * 24 * 60 ~/ count);
    final walk = [1.0];
    for (var i = 1; i < count; i++) {
      walk.add(walk.last * (1 + (random.nextDouble() - 0.5) * 0.03));
    }
    final scale = coin.currentPrice / walk.last;
    final now = DateTime.now();
    return [
      for (var i = 0; i < count; i++)
        ChartPoint(now.subtract(step * (count - 1 - i)), walk[i] * scale),
    ];
  }
}

Coin _coin(int rank, String id, String symbol, String name, double price,
    double supply, double? maxSupply, double change) {
  final cap = price * supply;
  return Coin(
    id: id,
    symbol: symbol,
    name: name,
    image: 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/$symbol.png',
    rank: rank,
    currentPrice: price,
    marketCap: cap,
    totalVolume: cap * 0.05,
    high24h: price * 1.03,
    low24h: price * 0.97,
    change24h: change,
    circulatingSupply: supply,
    totalSupply: maxSupply ?? supply,
    maxSupply: maxSupply,
    allTimeHigh: price * 1.6,
    allTimeLow: price * 0.02,
    description: 'Sample data for $name. Live details will come from the backend.',
  );
}

final _sampleCoins = [
  _coin(1, 'bitcoin', 'btc', 'Bitcoin', 67000, 19.7e6, 21e6, 1.8),
  _coin(2, 'ethereum', 'eth', 'Ethereum', 3500, 120.2e6, null, -0.9),
  _coin(3, 'tether', 'usdt', 'Tether', 1, 110e9, null, 0.01),
  _coin(4, 'binancecoin', 'bnb', 'BNB', 590, 147.6e6, 200e6, 0.7),
  _coin(5, 'solana', 'sol', 'Solana', 165, 445e6, null, 4.2),
  _coin(6, 'ripple', 'xrp', 'XRP', 0.52, 55e9, 100e9, -2.1),
  _coin(7, 'usd-coin', 'usdc', 'USDC', 1, 33e9, null, 0),
  _coin(8, 'cardano', 'ada', 'Cardano', 0.45, 35.7e9, 45e9, -1.4),
  _coin(9, 'dogecoin', 'doge', 'Dogecoin', 0.15, 144e9, null, 6.3),
  _coin(10, 'avalanche-2', 'avax', 'Avalanche', 35, 394e6, 720e6, 2.5),
  _coin(11, 'polkadot', 'dot', 'Polkadot', 7.1, 1.4e9, null, -3.2),
  _coin(12, 'chainlink', 'link', 'Chainlink', 14.5, 587e6, 1e9, 3.1),
];
