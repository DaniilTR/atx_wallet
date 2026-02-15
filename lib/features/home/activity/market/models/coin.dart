class Coin {
  final String id;
  final String symbol;
  final String name;
  final double priceUsd;
  final double change24h;
  final List<double>? sparkline;

  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.priceUsd,
    required this.change24h,
    this.sparkline,
  });

  String get formattedPrice {
    if (priceUsd >= 1) {
      return priceUsd.toStringAsFixed(2);
    }
    return priceUsd.toStringAsFixed(4);
  }

  String get formattedChange {
    final sign = change24h >= 0 ? '+' : '';
    return '$sign${change24h.toStringAsFixed(2)}%';
  }

  factory Coin.fromApi(String id, Map<String, dynamic> data) {
    final usd = (data['usd'] as num).toDouble();
    final change = (data['usd_24h_change'] as num).toDouble();
    final meta = _coinMeta[id];
    final symbol = meta?.symbol ?? id.toUpperCase();
    final name = meta?.name ?? symbol;
    return Coin(
      id: id,
      symbol: symbol,
      name: name,
      priceUsd: usd,
      change24h: change,
    );
  }

  factory Coin.fromMarketsApi(Map<String, dynamic> json) {
    final id = (json['id'] as String?) ?? '';
    final meta = _coinMeta[id];
    final symbol =
        meta?.symbol ?? ((json['symbol'] as String?) ?? '').toUpperCase();
    final name = meta?.name ?? ((json['name'] as String?) ?? symbol);
    final price = (json['current_price'] as num?)?.toDouble() ?? 0.0;
    final change =
        (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0;

    final spark =
        (json['sparkline_in_7d'] as Map<String, dynamic>?)?['price']
            as List<dynamic>?;
    final sparkline = spark == null
        ? null
        : spark
              .whereType<num>()
              .map((v) => v.toDouble())
              .toList(growable: false);

    return Coin(
      id: id,
      symbol: symbol,
      name: name,
      priceUsd: price,
      change24h: change,
      sparkline: sparkline,
    );
  }
}

class _CoinMeta {
  final String symbol;
  final String name;

  const _CoinMeta(this.symbol, this.name);
}

const Map<String, _CoinMeta> _coinMeta = {
  'ethereum': _CoinMeta('ETH/USDT', 'Ethereum / TetherUS'),
  'bitcoin': _CoinMeta('BTC/USDT', 'Bitcoin / TetherUS'),
  'solana': _CoinMeta('SOL/USDT', 'SOL / TetherUS'),
  'ripple': _CoinMeta('XRP/USDT', 'XRP / TetherUS'),
  'binancecoin': _CoinMeta('BNB/USDT', 'Binance Coin / TetherUS'),
  'litecoin': _CoinMeta('LTC/USDT', 'Litecoin / TetherUS'),
  'cosmos': _CoinMeta('ATOM/USDT', 'Cosmos / TetherUS'),
  'tron': _CoinMeta('TRX/USDT', 'TRON / TetherUS'),
  'toncoin': _CoinMeta('TON/USDT', 'TON / TetherUS'),
};
