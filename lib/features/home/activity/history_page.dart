import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:atx_wallet/features/auth/widgets/animated_neon_background.dart';
import 'package:atx_wallet/features/home/activity/qr_page.dart';
import 'package:atx_wallet/features/home/home_page.dart';
import 'package:atx_wallet/features/home/widgets/bottom_nav.dart';
import 'package:atx_wallet/providers/wallet_scope.dart';
import 'package:atx_wallet/services/auth_scope.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _tab = 3;

  void _handleTabChange(int value) {
    if (value == 0) {
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }
    if (value == 1) {
      Navigator.of(context).pushReplacementNamed('/market');
      return;
    }
    if (value == 2) {
      Navigator.of(context).pushReplacementNamed('/rewards');
      return;
    }
    setState(() => _tab = value);
  }

  Future<T?> _showNeonSheet<T>(Widget child) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: child,
        ),
      ),
    );
  }

  String? get _currentAddress {
    final wallet = WalletScope.of(context);
    return wallet.activeProfile?.addressHex;
  }

  Future<void> _openQrPage() async {
    final scanned = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => QrPage(address: _currentAddress)),
    );
    if (!mounted) return;
    if (scanned != null) {
      await _showNeonSheet<void>(
        SendSheet(address: _currentAddress, initialRecipient: scanned),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final wallet = WalletScope.of(context);
    final history = wallet.history;
    final loading = wallet.historyLoading;
    final error = wallet.historyError;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFF8E99C0)
        : const Color(0xFF475569);

    Widget content;
    if (loading && history.isEmpty) {
      content = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (history.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              color: isDark ? const Color(0xFF3F4B74) : const Color(0xFF64748B),
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              'Еще нет операций',
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Мы автоматически сохраняем отправки и поступления, даже оффлайн.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isDark ? const Color(0xFF7C86B2) : mutedTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      content = ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 190),
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
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          AnimatedNeonBackground(isDark: isDark),
          const Positioned(
            top: -40,
            right: -10,
            child: _GlowCircle(
              diameter: 240,
              color: Color.fromARGB(255, 125, 71, 250),
              opacity: 0.8,
            ),
          ),
          const Positioned(
            top: 250,
            left: -70,
            child: _GlowCircle(
              diameter: 200,
              color: Color(0xFF60A5FA),
              opacity: 0.7,
            ),
          ),
          const Positioned(
            bottom: -20,
            left: -40,
            child: _GlowCircle(
              diameter: 210,
              color: Color(0xFF7C3AED),
              opacity: 0.8,
            ),
          ),
          const Positioned(
            bottom: -20,
            right: -40,
            child: _GlowCircle(
              diameter: 220,
              color: Color(0xFF34D399),
              opacity: 0.8,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: HomeTopBar(
                    username: auth.currentUser?.username ?? 'Wallet',
                    isDark: isDark,
                    onSettings: () => Navigator.pushNamed(context, '/settings'),
                    onLogout: () async {
                      wallet.clearDevProfile();
                      await auth.logout();
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'История операций',
                        style: GoogleFonts.inter(
                          color: primaryTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Последние транзакции кошелька',
                        style: GoogleFonts.inter(
                          color: mutedTextColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: loading
                              ? null
                              : () => wallet.refreshHistory(),
                          icon: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            'Обновить',
                            style: GoogleFonts.inter(color: primaryTextColor),
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
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: content,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        index: _tab,
        onChanged: _handleTabChange,
        onQrTap: _openQrPage,
        isDark: isDark,
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.diameter,
    required this.color,
    this.opacity = 0.55,
  });

  final double diameter;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0.0)],
          ),
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
