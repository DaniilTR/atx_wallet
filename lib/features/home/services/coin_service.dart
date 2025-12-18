import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coin.dart';

class CoinService {
  // Returns a list of coins fetched from CoinGecko simple/price endpoint
  static Future<List<Coin>> fetchTopCoins() async {
    const ids = 'bitcoin,binancecoin,ethereum,solana';
    final uri = Uri.https('api.coingecko.com', '/api/v3/simple/price', {
      'ids': ids,
      'vs_currencies': 'usd',
      'include_24hr_change': 'true',
    });

    final res = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'User-Agent': 'atx_wallet/1.0'},
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load coin prices (${res.statusCode})');
    }

    final Map<String, dynamic> json =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List<Coin> result = [];
    for (final entry in json.entries) {
      final id = entry.key;
      final data = entry.value as Map<String, dynamic>;
      result.add(Coin.fromApi(id, data));
    }
    // Keep consistent order
    final order = ['BTC', 'BNB', 'ETH', 'SOL'];
    result.sort(
      (a, b) => order.indexOf(a.symbol).compareTo(order.indexOf(b.symbol)),
    );
    return result;
  }
}
