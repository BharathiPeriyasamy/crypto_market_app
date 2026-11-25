import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coin_model.dart';

class CryptoApiService {
  CryptoApiService({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.76.250.225:8000/api',
  );

  final http.Client _client;

  Future<List<Coin>> getCoins() async {
    final data = await _get('/coins') as List<dynamic>;
    return [for (final item in data) Coin.fromJson(item as Map<String, dynamic>)];
  }

  Future<MarketStats> getMarketStats() async {
    final data = await _get('/global') as Map<String, dynamic>;
    return MarketStats.fromJson(data);
  }

  // Coins and global stats together, fetched right away and then again
  // every [interval]. A failed fetch is sent as an error event and polling
  // carries on, so one bad request doesn't end live updates.
  Stream<(List<Coin>, MarketStats)> watchMarket({
    Duration interval = const Duration(seconds: 30),
  }) async* {
    while (true) {
      try {
        yield await (getCoins(), getMarketStats()).wait;
      } catch (e, stack) {
        yield* Stream.error(e, stack);
      }
      await Future<void>.delayed(interval);
    }
  }

  // Full details for one coin, including its description
  Future<Coin> getCoinDetail(String id) async {
    final data = await _get('/coins/$id') as Map<String, dynamic>;
    return Coin.fromJson(data);
  }

  // `days` of 0 asks for the coin's full history
  Future<List<ChartPoint>> getChart(Coin coin, int days) async {
    final range = days == 0 ? 'max' : '$days';
    final data = await _get('/coins/${coin.id}/chart?days=$range') as List<dynamic>;
    return [
      for (final point in data.cast<List<dynamic>>())
        ChartPoint(
          DateTime.fromMillisecondsSinceEpoch((point[0] as num).toInt()),
          (point[1] as num).toDouble(),
        ),
    ];
  }

  // Every endpoint replies {"source": ..., "data": ...}; returns `data`
  Future<Object?> _get(String path) async {
    final response = await _client
        .get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException('GET $path failed with ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'];
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}
