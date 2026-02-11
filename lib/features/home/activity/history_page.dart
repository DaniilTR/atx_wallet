import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/wallet_scope.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = WalletScope.of(context);
    final history = wallet.history;
    final loading = wallet.historyLoading;
    final error = wallet.historyError;
    final theme = Theme.of(context);

    Widget body;
    if (loading && history.isEmpty) {
      body = const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C86B2)),
        ),
      );
    } else if (history.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              color: Color(0xFF3F4B74),
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              'Еще нет операций',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Мы автоматически сохраняем отправки и поступления, даже оффлайн.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF7C86B2),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      body = ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final entry = history[index];
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
            contentPadding: EdgeInsets.zero,
            onTap: entry.txHash == null
                ? null
                : () => _copyTxHash(context, entry.txHash!),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0x222E9AFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            title: Text(
              isIncoming
                  ? 'Получение ${entry.tokenSymbol}'
                  : 'Отправка ${entry.tokenSymbol}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _formatHistorySubtitle(entry.timestamp, note),
              style: GoogleFonts.inter(
                color: const Color(0xFF7C86B2),
                fontSize: 12,
              ),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountSign${_formatNumber(entry.amount, precision: 6)} ${entry.tokenSymbol}',
                  style: GoogleFonts.inter(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.txHash != null)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Скопировать хеш',
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: Color(0xFF9FB1FF),
                    ),
                    onPressed: () => _copyTxHash(context, entry.txHash!),
                  ),
              ],
            ),
          );
        },
        separatorBuilder: (context, _) =>
            const Divider(color: Color(0x221C2743)),
        itemCount: history.length,
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'История операций',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Последние транзакции кошелька',
              style: GoogleFonts.inter(
                color: const Color(0xFF8E99C0),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: loading ? null : () => wallet.refreshHistory(),
                icon: loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF7C86B2),
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Обновить',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 4),
              Text(
                'Не удалось загрузить историю: $error',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF8F8F),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

Future<void> _copyTxHash(BuildContext context, String hash) async {
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: hash));
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFF1C1F33),
      content: Text(
        'Хеш скопирован',
        style: GoogleFonts.inter(color: Colors.white),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
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

String _formatNumber(double value, {int precision = 2}) {
  final text = value.toStringAsFixed(precision);
  if (!text.contains('.')) return text;
  return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}
