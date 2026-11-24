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
}

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
}

class ChartPoint {
  final DateTime time;
  final double price;

  const ChartPoint(this.time, this.price);
}
