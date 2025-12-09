part of '../home_page.dart';

class _HistorySheet extends StatelessWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context) {
    final wallet = WalletScope.of(context);
    final history = wallet.history;
    final loading = wallet.historyLoading;
    final error = wallet.historyError;

    Widget body;
    if (loading && history.isEmpty) {
      body = const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C86B2)),
        ),
      );
    } else if (history.isEmpty) {
      body = Column(
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
      );
    } else {
      body = ListView.separated(
        physics: const BouncingScrollPhysics(),
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

    return _SheetContainer(
      title: 'История операций',
      subtitle: 'Последние транзакции кошелька',
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          SizedBox(height: 300, child: body),
        ],
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
