import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

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

/// Сервис получения цен активов через публичный API CoinGecko.
///
/// Зачем он нужен:
/// - UI показывает стоимость **в долларах**;
/// - по ТЗ «стоимость в долларах по курсу USDT», поэтому в `WalletProvider`
///   цены нормализуются через USDT (USDT считается $1.00).
///
/// Важно:
/// - CoinGecko может отдавать ограничение по частоте запросов/ошибки; этот сервис бросает исключение,
///   а выше (в `WalletProvider.refreshBalances`) это превращается в текст ошибки.

class AssetPriceService {
  AssetPriceService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, double>> fetchUsdPrices({
    required Set<String> coinGeckoIds,
  }) async {
    if (coinGeckoIds.isEmpty) return <String, double>{};

    // Endpoint CoinGecko для простых цен:
    // GET /api/v3/simple/price?ids=...&vs_currencies=usd
    final base = Uri.parse(kCoinGeckoBaseUrl);
    final uri = base.replace(
      path: _joinBasePath(base, '/api/v3/simple/price'),
      queryParameters: {'ids': coinGeckoIds.join(','), 'vs_currencies': 'usd'},
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'atx_wallet/1.0',
      if (uri.host.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
    };

    final res = await _httpClient.get(uri, headers: headers);

    if (res.statusCode != 200) {
      throw StateError('Ошибка API цен (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Неожиданный формат ответа API цен');
    }

    final out = <String, double>{};
    for (final entry in decoded.entries) {
      final id = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        final usd = value['usd'];
        final price = usd is num ? usd.toDouble() : double.tryParse('$usd');
        if (price != null && price.isFinite && price > 0) {
          out[id] = price;
        }
      }
    }

    return out;
  }

  /// Возвращает «безопасную» цену USDT в USD.
  ///
  /// Если API недоступно или вернуло явно некорректные данные,
  /// возвращаем 1.0, чтобы приложение продолжило работать.
  double usdtUsdOrOne(double? apiPrice) {
    final value = apiPrice;
    if (value == null || !value.isFinite) return 1.0;
    // Базовая проверка здравого смысла: USDT должен быть около 1 USD.
    if (value < 0.5 || value > 2.0) return 1.0;
    return value;
  }

  void dispose() {
    _httpClient.close();
  }
}
