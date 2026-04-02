import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coin.dart';

import '../../../../../services/config.dart';

String _joinBasePath(Uri base, String endpointPath) {
  final rawBasePath = base.path;
  final basePath = (rawBasePath.isEmpty || rawBasePath == '/')
      ? ''
      : (rawBasePath.endsWith('/')
            ? rawBasePath.substring(0, rawBasePath.length - 1)
            : rawBasePath);
  final ep = endpointPath.startsWith('/') ? endpointPath : '/$endpointPath';
  return basePath.isEmpty ? ep : '$basePath$ep';
}

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
    final base = Uri.parse(kCoinGeckoBaseUrl);
    final uri = base.replace(
      path: _joinBasePath(base, '/api/v3/coins/markets'),
      queryParameters: {
        'vs_currency': 'usd',
        'ids': ids,
        'sparkline': 'true',
        'price_change_percentage': '24h',
        'per_page': order.length.toString(),
        'page': '1',
      },
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'atx_wallet/1.0',
      if (uri.host.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
    };

    final res = await http.get(uri, headers: headers);
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
