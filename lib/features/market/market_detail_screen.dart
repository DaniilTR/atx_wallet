import 'package:flutter/material.dart';
import '../../services/price_service.dart';

class MarketDetailScreen extends StatefulWidget {
  const MarketDetailScreen({super.key});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  final _priceService = PriceService();
  bool _loading = true;
  List<List<dynamic>>? _prices; // [timestamp, price]
  String? _coinId;
  String? _error;
  int? _selectedIndex;
  double? _lastTapX;

  @override
  void dispose() {
    _priceService.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final symbol = ModalRoute.of(context)!.settings.arguments as String;
    _coinId = PriceService.symbolToCoinGeckoId[symbol];
    _loadChart();
  }

  Future<void> _loadChart() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedIndex = null;
    });
    if (_coinId == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    try {
      final data = await _priceService.getMarketChart(_coinId!, days: 7);
      if (!mounted) return;
      setState(() {
        _prices = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить данные';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = ModalRoute.of(context)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(title: Text('$symbol details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadChart, child: const Text('Повторить')),
                      ],
                    ),
                  )
                : _coinId == null
                    ? const Center(child: Text('Price data not available for this token'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const Text('Last 7 days', style: TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _prices == null || _prices!.isEmpty
                                ? const Center(child: Text('No chart data', style: TextStyle(color: Colors.white70)))
                                : LayoutBuilder(builder: (context, constraints) {
                                    final fullWidth = constraints.maxWidth;
                                    const leftLabels = 64.0;
                                    final chartWidth = (fullWidth - leftLabels).clamp(100.0, fullWidth);
                                    return Row(
                                      children: [
                                        Container(
                                          width: leftLabels,
                                          padding: const EdgeInsets.only(right: 8),
                                          child: _YAxisLabels(data: _prices!),
                                        ),
                                        SizedBox(
                                          width: chartWidth,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTapDown: (ev) {
                                              final local = ev.localPosition;
                                              final n = _prices!.length;
                                              final stepX = chartWidth / (n - 1);
                                              final dx = local.dx.clamp(0.0, chartWidth);
                                              final idx = (dx / stepX).round().clamp(0, n - 1);
                                              setState(() {
                                                _selectedIndex = idx;
                                                _lastTapX = dx;
                                              });
                                            },
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: CustomPaint(
                                                    painter: _ChartPainter(_prices!, selectedIndex: _selectedIndex),
                                                  ),
                                                ),
                                                if (_selectedIndex != null)
                                                  Positioned(
                                                    left: (_lastTapX ?? 0) - 60,
                                                    top: 8,
                                                    child: _TooltipCard(entry: _prices![_selectedIndex!]),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<List<dynamic>> data;
  final int? selectedIndex;
  _ChartPainter(this.data, {this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF24E0F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final prices = data.map((p) => (p[1] as num).toDouble()).toList();
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final span = (max - min) == 0 ? 1.0 : (max - min);

    // grid
    final gridPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = i / gridLines * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final stepX = prices.length > 1 ? size.width / (prices.length - 1) : size.width;
    final path = Path();
    for (var i = 0; i < prices.length; i++) {
      final x = i * stepX;
      final y = size.height - ((prices[i] - min) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // selected point
    if (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < prices.length) {
      final idx = selectedIndex!;
      final sx = idx * stepX;
      final sy = size.height - ((prices[idx] - min) / span) * size.height;
      final dot = Paint()..color = const Color(0xFF24E0F9);
      canvas.drawCircle(Offset(sx, sy), 4.0, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _ChartPainter) {
      return oldDelegate.data != data || oldDelegate.selectedIndex != selectedIndex;
    }
    return true;
  }
}

class _YAxisLabels extends StatelessWidget {
  final List<List<dynamic>> data;
  const _YAxisLabels({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final prices = data.map((p) => (p[1] as num).toDouble()).toList();
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final mid = (min + max) / 2;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('\$${max.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text('\$${mid.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Text('\$${min.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _TooltipCard extends StatelessWidget {
  final List<dynamic> entry; // [timestamp, price]
  const _TooltipCard({required this.entry, super.key});

  @override
  Widget build(BuildContext context) {
    final ts = entry[0] as num;
    final price = (entry[1] as num).toDouble();
    final dt = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
    final label = '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    return Card(
      color: const Color(0xFF111827),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\$${price.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
