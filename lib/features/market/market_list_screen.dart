import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../providers/wallet_scope.dart';
import '../../providers/wallet_provider.dart';
import '../../services/price_service.dart';

class MarketListScreen extends StatefulWidget {
  const MarketListScreen({super.key});

  @override
  State<MarketListScreen> createState() => _MarketListScreenState();
}

class _MarketListScreenState extends State<MarketListScreen> {
  final _priceService = PriceService();
  Map<String, double?> _prices = {};
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 8;
  int _visibleCount = _pageSize;
  List<Map<String, dynamic>>? _catalog;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // initial load for first page
    _visibleCount = _pageSize;
    _loadCatalogAndInitial();
  }

  Future<void> _loadCatalogAndInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // try remote catalog first
    final remote = await _priceService.getTokenCatalog();
    final wallet = WalletScope.maybeOf(context);
    final owned = <String>{};
    if (wallet != null) {
      for (final a in wallet.balances.assets) {
        if (a.amount > 0) owned.add(a.token.symbol);
      }
    }
    List<Map<String, dynamic>> catalog;
    if (remote != null && remote.isNotEmpty) {
      catalog = remote.map((m) => Map<String, dynamic>.from(m)).toList();
    } else {
      // fallback to provider tokens
      final tokens = wallet?.supportedTokens ?? [];
      catalog = tokens.map((t) => {'symbol': t.symbol, 'name': t.name}).toList();
    }
    // sort: owned tokens first
    catalog.sort((a, b) {
      final aOwned = owned.contains(a['symbol']);
      final bOwned = owned.contains(b['symbol']);
      if (aOwned && !bOwned) return -1;
      if (!aOwned && bOwned) return 1;
      return (a['symbol'] as String).compareTo(b['symbol'] as String);
    });
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _loading = false;
      _visibleCount = math.min(_pageSize, _catalog!.length);
    });
    // load prices for initial visible set
    final initialSymbols = _catalog!.take(_visibleCount).map((e) => e['symbol'] as String).toList();
    await _loadPrices(initialSymbols);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final pos = _scrollController.position.pixels;
    if (pos >= max - 120 && !_loadingMore && !_loading) {
      _loadMoreIfNeeded();
    }
  }

  Future<void> _loadMoreIfNeeded() async {
    final total = _catalog?.length ?? 0;
    if (_catalog == null) return;
    if (_visibleCount >= total) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    final next = math.min(total, _visibleCount + _pageSize);
    final symbols = _catalog!.getRange(_visibleCount, next).map((t) => t['symbol'] as String).toList();
    final res = await _priceService.getPrices(symbols);
    if (!mounted) return;
    setState(() {
      _prices.addAll(res);
      _visibleCount = next;
      _loadingMore = false;
    });
  }

  /// Load prices for currently visible tokens. If [symbolsToFetch] is provided,
  /// fetch only those symbols and merge into cache.
  Future<void> _loadPrices([List<String>? symbolsToFetch]) async {
    final toFetch = symbolsToFetch ?? (_catalog?.take(_visibleCount).map((e) => e['symbol'] as String).toList() ?? []);
    if (toFetch.isEmpty) {
      setState(() {
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _priceService.getPrices(toFetch);
      if (!mounted) return;
      setState(() {
        _prices.addAll(res);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить цены';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _priceService.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog ?? [];
    final total = catalog.length;
    final visible = math.min(_visibleCount, total);
    return Scaffold(
      appBar: AppBar(title: const Text('Market')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadPrices, child: const Text('Повторить')),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: visible + (_visibleCount < total ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i >= visible) {
                      // loader item
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Center(child: _loadingMore ? const CircularProgressIndicator() : const SizedBox.shrink()),
                      );
                    }
                    final entry = catalog[i];
                    final symbol = entry['symbol'] as String;
                    final name = entry['name'] as String? ?? symbol;
                    final price = _prices[symbol];
                    return Card(
                      color: const Color(0xFF211E41),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.white24, child: Text(symbol[0])),
                        title: Text(name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(symbol, style: const TextStyle(color: Color(0xFFA6A6A6))),
                        trailing: Text(price != null ? '\$${price.toStringAsFixed(4)}' : '-', style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pushNamed(context, '/market/detail', arguments: symbol);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
