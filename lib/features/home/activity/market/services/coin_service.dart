import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coin.dart';

class CoinService {
  // Returns a list of coins fetched from CoinGecko markets endpoint (single call with sparkline)
  static Future<List<Coin>> fetchTopCoins() async {
    const order = [
      'ethereum',
      'bitcoin',
      'solana',
      'ripple',
      'binancecoin',
      'litecoin',
      'cosmos',
      'tron',
      'toncoin',
    ];
    final ids = order.join(',');
    final uri = Uri.https('api.coingecko.com', '/api/v3/coins/markets', {
      'vs_currency': 'usd',
      'ids': ids,
      'sparkline': 'true',
      'price_change_percentage': '24h',
      'per_page': order.length.toString(),
      'page': '1',
    });

    final res = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'User-Agent': 'atx_wallet/1.0'},
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load coin prices (${res.statusCode})');
    }

    final List<dynamic> json = jsonDecode(res.body) as List<dynamic>;
    final byId = <String, Coin>{
      for (final item in json.whereType<Map>())
        (item['id'] as String?) ?? '': Coin.fromMarketsApi(
          item.cast<String, dynamic>(),
        ),
    };

    return [
      for (final id in order)
        if (byId[id] != null) byId[id]!,
    ];
  }
}
