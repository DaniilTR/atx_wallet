import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple price service using CoinGecko public API.
class PriceService {
  PriceService({
    http.Client? client,
    this.maxRetries = 2,
    this.baseTimeout = const Duration(seconds: 6),
  }) : _client = client ?? http.Client();
  final http.Client _client;
  final int maxRetries;
  final Duration baseTimeout;

  // Map local token symbol -> CoinGecko id. Extend as needed.
  static const Map<String, String> symbolToCoinGeckoId = {
    'TBNB': 'binancecoin',
    'BNB': 'binancecoin',
    // ATX and LEV are test tokens — add mapping if listed on CoinGecko.
    // 'ATX': 'atx-token-id',
    // 'LEV': 'lev-token-id',
  };

  /// Get simple USD prices for given symbols. Returns map symbol->price (double) when available.
  Future<Map<String, double?>> getPrices(List<String> symbols) async {
    final ids = <String>[];
    final symbolToId = <String, String>{};
    for (final s in symbols) {
      final id = symbolToCoinGeckoId[s];
      if (id != null) {
        ids.add(id);
        symbolToId[s] = id;
      }
    }
    if (ids.isEmpty) return {for (var s in symbols) s: null};
    final uri = Uri.https('api.coingecko.com', '/api/v3/simple/price', {
      'ids': ids.join(','),
      'vs_currencies': 'usd',
    });
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final timeout = baseTimeout * (attempt == 1 ? 1 : attempt);
        final res = await _client.get(uri).timeout(timeout);
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final out = <String, double?>{};
          for (final s in symbols) {
            final id = symbolToId[s];
            if (id == null) {
              out[s] = null;
              continue;
            }
            final entry = json[id] as Map<String, dynamic>?;
            final price = entry == null
                ? null
                : (entry['usd'] as num?)?.toDouble();
            out[s] = price;
          }
          return out;
        }
        // non-200, treat as failure and retry if possible
      } catch (_) {
        // fallthrough to retry logic
      }
      if (attempt >= maxRetries) {
        return {for (var s in symbols) s: null};
      }
      // backoff before retry
      await Future.delayed(Duration(milliseconds: 250 * (1 << (attempt - 1))));
    }
  }

  /// Fetch market chart (prices) for coin id for last [days]. Returns list of price points (timestamp, price).
  Future<List<List<dynamic>>?> getMarketChart(
    String coinId, {
    int days = 7,
  }) async {
    final uri = Uri.https(
      'api.coingecko.com',
      '/api/v3/coins/$coinId/market_chart',
      {'vs_currency': 'usd', 'days': days.toString()},
    );
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final timeout =
            baseTimeout * (attempt == 1 ? 1 : attempt) +
            const Duration(seconds: 2);
        final res = await _client.get(uri).timeout(timeout);
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final prices = json['prices'] as List<dynamic>?;
          if (prices == null) return null;
          return prices.cast<List<dynamic>>();
        }
      } catch (_) {
        // ignore and retry
      }
      if (attempt >= maxRetries) return null;
      await Future.delayed(Duration(milliseconds: 300 * (1 << (attempt - 1))));
    }
  }

  void dispose() => _client.close();
}
