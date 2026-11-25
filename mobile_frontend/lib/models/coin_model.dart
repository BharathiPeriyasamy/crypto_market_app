class Coin {
  final String id;
  final String symbol;
  final String name;
  final String? image;
  final int rank;
  final double currentPrice;
  final double marketCap;
  final double totalVolume;
  final double high24h;
  final double low24h;
  final double change24h;
  final double circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final double allTimeHigh;
  final double allTimeLow;
  final String description;

  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    this.image,
    required this.rank,
    required this.currentPrice,
    required this.marketCap,
    required this.totalVolume,
    required this.high24h,
    required this.low24h,
    required this.change24h,
    required this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    required this.allTimeHigh,
    required this.allTimeLow,
    required this.description,
  });

  // Backend /coins and /coins/<id> both use CoinGecko field names.
  // CoinGecko sends null for some numbers on small coins, so default to 0.
  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      rank: (json['market_cap_rank'] as num?)?.toInt() ?? 0,
      currentPrice: _toDouble(json['current_price']),
      marketCap: _toDouble(json['market_cap']),
      totalVolume: _toDouble(json['total_volume']),
      high24h: _toDouble(json['high_24h']),
      low24h: _toDouble(json['low_24h']),
      change24h: _toDouble(json['price_change_percentage_24h']),
      circulatingSupply: _toDouble(json['circulating_supply']),
      totalSupply: (json['total_supply'] as num?)?.toDouble(),
      maxSupply: (json['max_supply'] as num?)?.toDouble(),
      allTimeHigh: _toDouble(json['ath']),
      allTimeLow: _toDouble(json['atl']),
      description: (json['description'] as String?)?.trim() ?? '',
    );
  }
}

double _toDouble(Object? value) => (value as num?)?.toDouble() ?? 0;

class MarketStats {
  final double totalMarketCap;
  final double totalVolume;
  final double marketCapChange24h;
  final double btcDominance;
  final double ethDominance;
  final int activeCoins;
  final int markets;

  const MarketStats({
    required this.totalMarketCap,
    required this.totalVolume,
    required this.marketCapChange24h,
    required this.btcDominance,
    required this.ethDominance,
    required this.activeCoins,
    required this.markets,
  });

  factory MarketStats.fromJson(Map<String, dynamic> json) {
    return MarketStats(
      totalMarketCap: _toDouble(json['total_market_cap_usd']),
      totalVolume: _toDouble(json['total_volume_usd']),
      marketCapChange24h:
          _toDouble(json['market_cap_change_percentage_24h_usd']),
      btcDominance: _toDouble(json['btc_dominance']),
      ethDominance: _toDouble(json['eth_dominance']),
      activeCoins: (json['active_cryptocurrencies'] as num?)?.toInt() ?? 0,
      markets: (json['markets'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChartPoint {
  final DateTime time;
  final double price;

  const ChartPoint(this.time, this.price);
}
