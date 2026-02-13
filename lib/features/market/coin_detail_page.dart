import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/price_service.dart';

class CoinDetailPage extends StatefulWidget {
  const CoinDetailPage({
    super.key,
    required this.symbol,
    required this.name,
    this.coinId,
    this.priceUsd,
    this.change24h,
  });

  final String symbol;
  final String name;
  final String? coinId;
  final double? priceUsd;
  final double? change24h;

  @override
  State<CoinDetailPage> createState() => _CoinDetailPageState();
}

class _CoinDetailPageState extends State<CoinDetailPage> {
  final PriceService _priceService = PriceService();
  bool _loading = false;
  String? _error;
  List<double> _series = const [];
  int _days = 7;
  double? _price;
  double? _change;

  @override
  void initState() {
    super.initState();
    _price = widget.priceUsd;
    _change = widget.change24h;
    _loadChart();
  }

  @override
  void dispose() {
    _priceService.dispose();
    super.dispose();
  }

  Future<void> _loadChart() async {
    final id = widget.coinId;
    if (id == null) {
      setState(() {
        _error = 'Нет данных для графика.';
        _series = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final prices = await _priceService.getMarketChart(id, days: _days);
    if (!mounted) return;
    if (prices == null || prices.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить график.';
        _series = const [];
      });
      return;
    }
    final values = prices
        .map((entry) => (entry.length > 1 ? entry[1] : null))
        .whereType<num>()
        .map((e) => e.toDouble())
        .toList(growable: false);
    double? change;
    if (values.length >= 2) {
      final first = values.first;
      final last = values.last;
      if (first != 0) {
        change = (last - first) / first * 100;
      }
    }
    setState(() {
      _loading = false;
      _series = values;
      _price = _price ?? (values.isNotEmpty ? values.last : null);
      _change = _change ?? change;
    });
  }

  void _setDays(int days) {
    if (_days == days) return;
    setState(() => _days = days);
    _loadChart();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceText = _price == null
        ? '—'
        : _price! >= 1
        ? _price!.toStringAsFixed(2)
        : _price!.toStringAsFixed(4);
    final changeValue = _change ?? 0;
    final isNegative = changeValue < 0;
    final changeText = _change == null
        ? '—'
        : '${changeValue >= 0 ? '+' : ''}${changeValue.toStringAsFixed(2)}%';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.star_border_rounded),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.name,
              style: GoogleFonts.inter(
                color: const Color(0xFF8E99C0),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '$priceText \$',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              changeText,
              style: GoogleFonts.inter(
                color: _change == null
                    ? const Color(0xFF8E99C0)
                    : isNegative
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF40C977),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x151E2542),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x221B2546)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF7C86B2),
                            ),
                          ),
                        )
                      : _series.length < 2
                      ? Center(
                          child: Text(
                            _error ?? 'Нет данных для графика',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8E99C0),
                            ),
                          ),
                        )
                      : CustomPaint(
                          painter: _PriceChartPainter(
                            data: _series,
                            color: isNegative
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF40C977),
                          ),
                          child: const SizedBox.expand(),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimeRangeButton(
                  label: '1д',
                  active: _days == 1,
                  onTap: () => _setDays(1),
                ),
                _TimeRangeButton(
                  label: '1н',
                  active: _days == 7,
                  onTap: () => _setDays(7),
                ),
                _TimeRangeButton(
                  label: '1м',
                  active: _days == 30,
                  onTap: () => _setDays(30),
                ),
                _TimeRangeButton(
                  label: '1г',
                  active: _days == 365,
                  onTap: () => _setDays(365),
                ),
                _TimeRangeButton(
                  label: 'Всё',
                  active: _days == 1825,
                  onTap: () => _setDays(1825),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Покупка',
                    filled: true,
                    onTap: () => _showStub(context, 'Покупка в разработке'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Продажа',
                    filled: false,
                    onTap: () => _showStub(context, 'Продажа в разработке'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRangeButton extends StatelessWidget {
  const _TimeRangeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : const Color(0xFF8E99C0);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: active
                ? const Color(0xFF1C233D)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = filled ? const Color(0xFF4DE8A4) : Colors.transparent;
    final borderColor = filled ? Colors.transparent : const Color(0xFF2E3654);
    final textColor = filled ? const Color(0xFF0F172A) : Colors.white;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue) == 0 ? 1 : (maxValue - minValue);

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

void _showStub(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFF1C1F33),
      content: Text(text, style: GoogleFonts.inter(color: Colors.white)),
    ),
  );
}
