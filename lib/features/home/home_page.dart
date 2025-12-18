import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/config.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'models/coin.dart';
import 'services/coin_service.dart';

import '../../providers/wallet_scope.dart';
import '../../providers/wallet_provider.dart';
import '../../services/auth_scope.dart';
import '../auth/widgets/animated_neon_background.dart';
import '../auth/widgets/glass_card.dart';
import 'home_route_args.dart';

part 'slides/sheet_container.dart';
part 'slides/send_sheet.dart';
part 'slides/receive_sheet.dart';
part 'slides/buy_sheet.dart';
part 'slides/swap_sheet.dart';
part 'slides/popular_coins_sheet.dart';
part 'slides/history_sheet.dart';
part 'slides/qr_sheet.dart';
part 'slides/labeled_field.dart';
part 'slides/primary_button.dart';
part 'slides/info_chip.dart';
part 'slides/swap_card.dart';

const Map<String, Color> _tokenColors = <String, Color>{
  'TBNB': Color(0xFF5782FF),
  'ATX': Color(0xFF3DD5D0),
  'LEV': Color(0xFFF7C344),
};

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WalletScope.read(context).refreshBalances(silent: true);
    });
  }

  Future<void> _refreshBalances() {
    return WalletScope.read(context).refreshBalances();
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

  Future<void> _openSendSheet({String? recipient}) => _showNeonSheet<void>(
    _SendSheet(address: _currentAddress, initialRecipient: recipient),
  );

  Future<void> _openReceiveSheet() =>
      _showNeonSheet(_ReceiveSheet(address: _currentAddress));

  Future<void> _openBuySheet() => _showNeonSheet(const _BuySheet());

  Future<void> _openSwapSheet() => _showNeonSheet(const _SwapSheet());

  Future<void> _openPopularSheet() =>
      _showNeonSheet(const _PopularCoinsSheet());

  Future<void> _openHistorySheet() => _showNeonSheet(const _HistorySheet());

  Future<void> _openQrSheet() async {
    final scanned = await _showNeonSheet<String?>(
      _QrSheet(address: _currentAddress),
    );
    if (!mounted) return;
    if (scanned != null) {
      await _openSendSheet(recipient: scanned);
    }
  }

  String? get _currentAddress {
    final wallet = WalletScope.of(context);
    final args = ModalRoute.of(context)?.settings.arguments as HomeRouteArgs?;
    final profile = wallet.activeProfile ?? args?.devProfile;
    return profile?.addressHex;
  }

  void _handleTabChange(int value) {
    if (value == 2) {
      Navigator.pushNamed(context, '/settings');
      return;
    }
    setState(() => _tab = value);
    if (value == 1) {
      _openPopularSheet();
    } else if (value == 3) {
      _openHistorySheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final wallet = WalletScope.of(context);
    final balances = wallet.balances;
    final args = ModalRoute.of(context)?.settings.arguments as HomeRouteArgs?;
    final profile = wallet.activeProfile ?? args?.devProfile;
    final address = profile?.addressHex;
    final username = auth.currentUser?.username ?? 'Wallet';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFFB3B8D7)
        : const Color(0xFF475569);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    return Scaffold(
      extendBody: true,
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        toolbarHeight: 65,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const _NeonAvatar(),
              const SizedBox(width: 12),
              Text(
                username,
                style: GoogleFonts.inter(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, color: mutedTextColor),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: Icon(Icons.settings, color: mutedTextColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Выйти',
              onPressed: () async {
                wallet.clearDevProfile();
                await auth.logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: Icon(Icons.logout_rounded, color: mutedTextColor),
            ),
          ),
        ],
      ),

      // Цветные круглишки на фоне
      //------------------------------------------------------------------------
      body: Stack(
        children: [
          AnimatedNeonBackground(isDark: isDark),
          const Positioned(
            top: -60,
            right: -10,
            child: _GlowCircle(diameter: 240, color: Color(0xFF6D63FF)),
          ),
          const Positioned(
            bottom: 180,
            left: -90,
            child: _GlowCircle(diameter: 320, color: Color(0xFF34E5A2)),
          ),
          const Positioned(
            bottom: -40,
            right: -70,
            child: _GlowCircle(diameter: 260, color: Color(0xFF4C6BFF)),
          ),

          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 190),
              children: [
                _BalanceCard(
                  address: address,
                  balances: balances,
                  isDark: isDark,
                  onCopy: () async {
                    if (address == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          content: Text(
                            'Address is not ready yet',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    await Clipboard.setData(ClipboardData(text: address));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1C1F33),
                        content: Text(
                          'Address copied',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                _ActionsRow(
                  isDark: isDark,
                  onSend: _openSendSheet,
                  onReceive: _openReceiveSheet,
                  onBuy: _openBuySheet,
                  onSwap: _openSwapSheet,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/mobile/pair',
                          );
                          if (result is Map) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Сессия получена, подключаемся...',
                                ),
                              ),
                            );
                            try {
                              // Отправляем сессию на бэкенд
                              final session = result['session'] as String?;
                              if (session != null) {
                                final uri = ApiConfig.apiUri('/api/pairings');
                                final payload = <String, dynamic>{
                                  'session': session,
                                };
                                // Если есть адрес, добавляем его
                                final sentAddress =
                                    result['address'] as String? ?? address;
                                if (sentAddress != null)
                                  payload['address'] = sentAddress;
                                await http.post(
                                  uri,
                                  body: jsonEncode(payload),
                                  headers: {'Content-Type': 'application/json'},
                                );
                              }
                            } catch (_) {
                              // игнорируем ошибки
                            }
                          }
                        },
                        icon: const Icon(Icons.link),
                        label: const Text('Подключить к ПК (QR)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Мой кошелек',
                      style: GoogleFonts.inter(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      splashRadius: 18,
                      tooltip: 'Обновить баланс',
                      onPressed: balances.isLoading
                          ? null
                          : () => _refreshBalances(),
                      icon: balances.isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFB0BBCE),
                                ),
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                      color: mutedTextColor,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < balances.assets.length; i++) ...[
                  _AssetTile(
                    balance: balances.assets[i],
                    color:
                        _tokenColors[balances.assets[i].token.symbol] ??
                        const Color(0xFF4C6BFF),
                    bnbUsdPrice: balances.bnbUsdPrice,
                  ),
                  if (i != balances.assets.length - 1)
                    const SizedBox(height: 14),
                ],
                if (balances.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Не удалось обновить баланс: ${balances.error}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFF8F8F),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onChanged: _handleTabChange,
        onQrTap: _openQrSheet,
        isDark: isDark,
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.onCopy,
    required this.balances,
    required this.isDark,
    this.address,
  });

  final VoidCallback onCopy;
  final WalletBalances balances;
  final String? address;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final displayAddress = address == null
        ? null
        : address!.length > 12
        ? '${address!.substring(0, 6)}...${address!.substring(address!.length - 4)}'
        : address!;
    final borderTint = Colors.white.withOpacity(0.22);
    final totalUsd = balances.totalUsd;
    final totalTbnb = balances.totalTbnb;
    final loading = balances.isLoading;
    final updatedLabel = _formatTimestamp(balances.updatedAt);

    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(),
        child: GlassCard(
          borderRadius: 36,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color.fromARGB(66, 25, 27, 37),
                        Color.fromARGB(19, 25, 35, 65),
                      ]
                    : const [
                        Color.fromARGB(80, 111, 143, 255),
                        Color.fromARGB(19, 145, 174, 231),
                      ],
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: borderTint, width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66101B4B),
                  blurRadius: 45,
                  offset: Offset(0, 28),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(
              0, // left
              22, // top
              0, // right
              0, // bottom
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Общий баланс',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFE8EEFF),
                          fontSize: 13,
                          letterSpacing: .3,
                        ),
                      ),
                      const Spacer(),
                      _GrowthPill(
                        value: loading
                            ? 'Обновляем'
                            : 'Обновлено: $updatedLabel',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        totalUsd != null
                            ? '\$${_formatNumber(totalUsd, precision: 2)}'
                            : '${_formatNumber(totalTbnb, precision: 4)} TBNB',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        totalUsd == null
                            ? 'Без оценки в USD'
                            : '≈ ${_formatNumber(totalTbnb, precision: 4)} TBNB',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB7C4EA),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3F52),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33090F23),
                        blurRadius: 24,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Твой адрес',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayAddress ?? '—',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFD3DAED),
                                letterSpacing: .2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: onCopy,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withOpacity(.08),
                            border: Border.all(
                              color: Colors.white.withOpacity(.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.copy_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.isDark,
    required this.onSend,
    required this.onReceive,
    required this.onBuy,
    required this.onSwap,
  });

  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onBuy;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: Icons.north_east_rounded,
          label: 'Отправить',
          onTap: onSend,
          isDark: isDark,
        ),
        _ActionButton(
          icon: Icons.south_rounded,
          label: 'Получить',
          onTap: onReceive,
          isDark: isDark,
        ),
        _ActionButton(
          icon: Icons.attach_money_rounded,
          label: 'Купить',
          onTap: onBuy,
          isDark: isDark,
        ),
        _ActionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Обменять',
          onTap: onSwap,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
                colors: isDark
                    ? const [Color(0xFF27305A), Color(0xFF171C33)]
                    : const [Color(0xFFF6F9FF), Color(0xFFE0E7F3)],
              ),
              border: Border.all(
                color: isDark
                    ? const Color(0x33FFFFFF)
                    : const Color(0xFFD1D5E0),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color(0x44090F25)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFFEFF2FF) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: .1,
              color: isDark ? const Color(0xFFCAD0E4) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.balance,
    required this.color,
    this.bnbUsdPrice,
  });

  final AssetBalance balance;
  final Color color;
  final double? bnbUsdPrice;

  @override
  Widget build(BuildContext context) {
    final amountLabel =
        '${_formatNumber(balance.amount, precision: 6)} ${balance.token.symbol}';
    final tbnbLabel =
        '≈ ${_formatNumber(balance.tbnbValue, precision: 4)} TBNB';
    final usdValue = bnbUsdPrice == null
        ? null
        : balance.tbnbValue * bnbUsdPrice!;
    final valueLabel = usdValue == null
        ? tbnbLabel
        : '\$${_formatNumber(usdValue, precision: 2)}';
    final secondaryLabel = usdValue == null ? amountLabel : tbnbLabel;

    return GlassCard(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(.32), const Color(0x120F1935)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x1CFFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33090F23),
              blurRadius: 28,
              offset: Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(.45)],
                ),
                border: Border.all(color: const Color(0x26FFFFFF)),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(.45), blurRadius: 20),
                ],
              ),
              child: const Icon(
                Icons.currency_bitcoin_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balance.token.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    balance.token.symbol,
                    style: GoogleFonts.inter(color: const Color(0xFF9FB3D8)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    amountLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueLabel,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  secondaryLabel,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9FB3D8),
                    fontSize: 12,
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

String _formatNumber(double value, {int precision = 2}) {
  final text = value.toStringAsFixed(precision);
  if (!text.contains('.')) return text;
  return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

String _formatTimestamp(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final ss = local.second.toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}

class _NeonAvatar extends StatelessWidget {
  const _NeonAvatar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFB084FF), Color(0xFF6A63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x804B46FF), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: isDark
            ? const Color(0xFF1B2032)
            : const Color.fromARGB(255, 227, 233, 255),
        child: Icon(
          Icons.person,
          size: 18,
          color: isDark
              ? Colors.white
              : const Color.fromARGB(255, 50, 122, 206),
        ),
      ),
    );
  }
}

class _GrowthPill extends StatelessWidget {
  const _GrowthPill({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          const Icon(Icons.trending_up, size: 16, color: Color(0xFF16273E)),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: const Color.fromARGB(255, 76, 82, 90),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onChanged,
    required this.onQrTap,
    required this.isDark,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onQrTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Stack(
        children: [
          Container(
            height: 100,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF485ACD), Color(0xFF3A1C7C)]
                    : const [
                        Color.fromARGB(255, 121, 153, 255),
                        Color.fromARGB(255, 96, 133, 255),
                      ],
              ),
            ),
          ),
          BottomAppBar(
            color: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: const CircularNotchedRectangle(),
            child: SizedBox(
              width: double.infinity,
              height: 100,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned.fill(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _NavIcon(
                                  icon: Icons.home_rounded,
                                  active: index == 0,
                                  onTap: () => onChanged(0),
                                  activeColor: Colors.white,
                                ),
                                const SizedBox(width: 20),
                                _NavIcon(
                                  icon: Icons.pie_chart_rounded,
                                  active: index == 1,
                                  onTap: () => onChanged(1),
                                  activeColor: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 80),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _NavIcon(
                                  icon: Icons.settings_rounded,
                                  active: index == 2,
                                  onTap: () => onChanged(2),
                                  activeColor: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E3A8A),
                                ),
                                const SizedBox(width: 20),
                                _NavIcon(
                                  icon: Icons.table_rows_rounded,
                                  active: index == 3,
                                  onTap: () => onChanged(3),
                                  activeColor: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E3A8A),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -8,
                    child: GestureDetector(
                      onTap: onQrTap,
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF80B7FF), Color(0xFF6F5CFF)],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(.3),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xAA2634A7),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 30,
                          color: Color(0xFF0F1733),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.activeColor,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: active ? activeColor : const Color(0xFFD2D8F6),
        size: 26,
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.diameter,
    required this.color,
    // ignore: unused_element_parameter
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
