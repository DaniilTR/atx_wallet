class Coin {
  final String symbol;
  final double priceUsd;
  final double change24h;

  const Coin({
    required this.symbol,
    required this.priceUsd,
    required this.change24h,
  });

  String get formattedPrice =>
      priceUsd.toStringAsFixed(priceUsd >= 1000 ? 2 : 2);

  String get formattedChange {
    final sign = change24h >= 0 ? '+' : '';
    return '$sign${change24h.toStringAsFixed(2)}%';
  }

  factory Coin.fromApi(String id, Map<String, dynamic> data) {
    final usd = (data['usd'] as num).toDouble();
    final change = (data['usd_24h_change'] as num).toDouble();
    // map common ids to symbols
    final symbol = _idToSymbol[id] ?? id.toUpperCase();
    return Coin(symbol: symbol, priceUsd: usd, change24h: change);
  }
}

const Map<String, String> _idToSymbol = {
  'bitcoin': 'BTC',
  'ethereum': 'ETH',
  'binancecoin': 'BNB',
  'solana': 'SOL',
};
