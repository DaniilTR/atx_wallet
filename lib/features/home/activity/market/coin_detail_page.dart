// home/activity/market/coin_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../providers/wallet_scope.dart';
import '../../../../services/config.dart';
import '../../../../WalletSecureStorage/history_model/transaction_record.dart';

/// Экран деталей монеты/актива.
///
/// Что показывает:
/// - текущую цену (USD) и изменение (%), если они переданы извне;
/// - баланс пользователя по этому символу из `WalletProvider`;
/// - простой график цены за период через CoinGecko market_chart.
///
/// Примечание про цены:
/// - В приложении «основная оценка» на главной считается в `WalletProvider`
///   как USD-значение, нормализованное через USDT.
/// - Здесь график берётся в “сырых” USD от CoinGecko и используется только
///   для отображения, без пересчёта через USDT.
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
  // Внутренний сервис для чтения графика (отдельно от `AssetPriceService`,
  // потому что тут нужен именно endpoint market_chart).
  final _CoinGeckoPriceService _priceService = _CoinGeckoPriceService();
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

    // change% считаем по первому и последнему значению.
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
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFF8E99C0)
        : const Color(0xFF475569);
    final surfaceColor = isDark
        ? const Color(0x151E2542)
        : Colors.black.withValues(alpha: 0.03);
    final surfaceBorderColor = isDark
        ? const Color(0x221B2546)
        : Colors.black.withValues(alpha: 0.08);
    final wallet = WalletScope.of(context);

    final symbolKey = widget.symbol.trim().toUpperCase();
    final filteredHistory = wallet.history
        .where((e) => e.tokenSymbol.trim().toUpperCase() == symbolKey)
        .toList(growable: false);
    final balance = wallet.balanceForSymbol(widget.symbol);
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
    final amount = balance?.amount ?? 0;
    final amountLabel =
        '${_formatNumber(amount, precision: 6)} ${widget.symbol}';
    final usdValue = _price == null ? null : amount * _price!;
    final usdLabel = usdValue == null
        ? '—'
        : '\$${_formatNumber(usdValue, precision: 2)}';
    final isFavorite = wallet.isFavoriteAsset(
      symbol: widget.symbol,
      coinGeckoId: widget.coinId,
    );
    final isPinned = wallet.isPinnedSymbol(widget.symbol);
    final favoriteStarColor = const Color(0xFFF7C344);

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
            onPressed: isPinned
                ? null
                : () => wallet.toggleFavoriteAsset(
                    symbol: widget.symbol,
                    name: widget.name,
                    coinGeckoId: widget.coinId,
                  ),
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: (isFavorite || isPinned) ? favoriteStarColor : null,
            ),
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.name,
              style: GoogleFonts.inter(color: mutedTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 8),
            Text(
              '$priceText \$',
              style: GoogleFonts.inter(
                color: primaryTextColor,
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
            const SizedBox(height: 16),
            _BalanceFrame(
              symbol: widget.symbol,
              name: widget.name,
              amountLabel: amountLabel,
              usdLabel: usdLabel,
            ),
            const SizedBox(height: 16),
            _QuickActionsRow(
              onSend: () => _showStub(context, 'Отправка в разработке'),
              onReceive: () => _showStub(context, 'Получение в разработке'),
              onBuy: () => _showStub(context, 'Покупка в разработке'),
              onSwap: () => _showStub(context, 'Обмен в разработке'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: surfaceBorderColor),
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

            const SizedBox(height: 22),
            Text(
              'История операций',
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Последние транзакции по ${widget.symbol}',
              style: GoogleFonts.inter(color: mutedTextColor, fontSize: 13),
            ),
            if (wallet.historyError != null) ...[
              const SizedBox(height: 10),
              Text(
                'Не удалось загрузить историю: ${wallet.historyError}',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF8F8F),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: surfaceBorderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: _TokenHistoryList(
                  symbol: widget.symbol,
                  entries: filteredHistory,
                  loading: wallet.historyLoading,
                  primaryTextColor: primaryTextColor,
                  mutedTextColor: mutedTextColor,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenHistoryList extends StatelessWidget {
  const _TokenHistoryList({
    required this.symbol,
    required this.entries,
    required this.loading,
    required this.primaryTextColor,
    required this.mutedTextColor,
    required this.isDark,
  });

  final String symbol;
  final List<TransactionRecord> entries;
  final bool loading;
  final Color primaryTextColor;
  final Color mutedTextColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (loading && entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              color: isDark ? const Color(0xFF3F4B74) : const Color(0xFF64748B),
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              'Нет операций по $symbol',
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Отправки и поступления сохраняются локально.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isDark ? const Color(0xFF7C86B2) : mutedTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, index) => const Divider(color: Color(0x221C2743)),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isIncoming = entry.incoming;
        final amountSign = isIncoming ? '+' : '-';
        final amountColor = isIncoming
            ? const Color(0xFF5EF2C1)
            : const Color(0xFFFF8484);
        final icon = isIncoming
            ? Icons.arrow_downward_rounded
            : Icons.arrow_outward_rounded;
        final note = entry.note;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x222E9AFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primaryTextColor, size: 20),
          ),
          title: Text(
            isIncoming
                ? 'Получение ${entry.tokenSymbol}'
                : 'Отправка ${entry.tokenSymbol}',
            style: GoogleFonts.inter(
              color: primaryTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            _formatHistorySubtitle(entry.timestamp, note),
            style: GoogleFonts.inter(
              color: isDark ? const Color(0xFF7C86B2) : mutedTextColor,
              fontSize: 12,
            ),
          ),
          trailing: Text(
            '$amountSign${_formatNumber(entry.amount, precision: 6)} ${entry.tokenSymbol}',
            style: GoogleFonts.inter(
              color: amountColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }
}

class _BalanceFrame extends StatelessWidget {
  const _BalanceFrame({
    required this.symbol,
    required this.name,
    required this.amountLabel,
    required this.usdLabel,
  });

  final String symbol;
  final String name;
  final String amountLabel;
  final String usdLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFF8E99C0)
        : const Color(0xFF475569);
    final surfaceColor = isDark
        ? const Color(0x151E2542)
        : Colors.black.withValues(alpha: 0.03);
    final surfaceBorderColor = isDark
        ? const Color(0x221B2546)
        : Colors.black.withValues(alpha: 0.08);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33090F23),
            blurRadius: 18,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFB923C)],
                ),
              ),
              child: Center(
                child: Text(
                  symbol.substring(0, 1),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amountLabel,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9FB1FF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  usdLabel,
                  style: GoogleFonts.inter(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Мой баланс',
                  style: GoogleFonts.inter(color: mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onSend,
    required this.onReceive,
    required this.onBuy,
    required this.onSwap,
  });

  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onBuy;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionButton(
          icon: Icons.north_east_rounded,
          label: 'Отправить',
          onTap: onSend,
        ),
        _QuickActionButton(
          icon: Icons.south_rounded,
          label: 'Получить',
          onTap: onReceive,
        ),
        _QuickActionButton(
          icon: Icons.attach_money_rounded,
          label: 'Купить',
          onTap: onBuy,
        ),
        _QuickActionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Обменять',
          onTap: onSwap,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark
        ? const Color(0xFFCAD0E4)
        : const Color(0xFF475569);
    final backgroundA = isDark
        ? const Color.fromARGB(255, 30, 30, 45)
        : theme.colorScheme.surface;
    final backgroundB = isDark
        ? const Color.fromARGB(255, 30, 30, 45)
        : theme.colorScheme.surface;
    final iconColor = isDark
        ? const Color(0xFFEFF2FF)
        : theme.colorScheme.onSurface;
    final shadowColor = isDark
        ? const Color(0x44090F25)
        : Colors.black.withValues(alpha: 0.08);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(31),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [backgroundA, backgroundB],
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: .1,
              color: labelColor,
            ),
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFF8E99C0)
        : const Color(0xFF475569);
    final color = active ? primaryTextColor : mutedTextColor;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: active
                ? (isDark
                      ? const Color(0xFF1C233D)
                      : Colors.black.withValues(alpha: 0.05))
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final background = filled ? const Color(0xFF4DE8A4) : Colors.transparent;
    final borderColor = filled
        ? Colors.transparent
        : (isDark
              ? const Color(0xFF2E3654)
              : Colors.black.withValues(alpha: 0.12));
    final textColor = filled ? const Color(0xFF0F172A) : primaryTextColor;
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

String _formatNumber(double value, {int precision = 2}) {
  final text = value.toStringAsFixed(precision);
  if (!text.contains('.')) return text;
  return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

String _formatHistorySubtitle(DateTime timestamp, String? note) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);
  final datePart = difference.inDays == 0
      ? 'Сегодня'
      : difference.inDays == 1
      ? 'Вчера'
      : '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}';
  final timePart =
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  final base = '$datePart, $timePart';
  if (note == null || note.isEmpty) return base;
  return '$base · $note';
}

void _showStub(BuildContext context, String text) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isDark ? const Color(0xFF1C1F33) : Colors.white,
      content: Text(
        text,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    ),
  );
}

class _CoinGeckoPriceService {
  _CoinGeckoPriceService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// Возвращает список точек графика цены из CoinGecko market_chart.
  ///
  /// Формат элемента: `[timestampMs, priceUsd]`.
  Future<List<List<num>>?> getMarketChart(
    String coinId, {
    required int days,
  }) async {
    final base = Uri.parse(kCoinGeckoBaseUrl);
    final uri = base.replace(
      path: '/api/v3/coins/$coinId/market_chart',
      queryParameters: {'vs_currency': 'usd', 'days': days.toString()},
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': 'atx_wallet/1.0',
      if (uri.host.contains('ngrok')) 'ngrok-skip-browser-warning': 'true',
    };

    final res = await _httpClient.get(
      uri,
      headers: headers,
    );
    if (res.statusCode != 200) return null;

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) return null;
    final prices = decoded['prices'];
    if (prices is! List) return null;

    final out = <List<num>>[];
    for (final item in prices) {
      if (item is List &&
          item.length >= 2 &&
          item[0] is num &&
          item[1] is num) {
        out.add([item[0] as num, item[1] as num]);
      }
    }
    return out;
  }

  void dispose() {
    _httpClient.close();
  }
}
