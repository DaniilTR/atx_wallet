import 'package:flutter/material.dart';
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
      // Цветные круглишки на фоне
      //------------------------------------------------------------------------
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
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 190),
              children: [
                HomeTopBar(
                  username: username,
                  isDark: isDark,
                  onSettings: () => Navigator.pushNamed(context, '/settings'),
                  onLogout: () async {
                    wallet.clearDevProfile();
                    await auth.logout();
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
                const SizedBox(height: 12),
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
          borderRadius: 24,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color.fromARGB(34, 25, 27, 37),
                        Color.fromARGB(19, 25, 35, 65),
                      ]
                    : const [
                        Color.fromARGB(34, 111, 142, 255),
                        Color.fromARGB(15, 145, 174, 231),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
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
                    ? const [
                        Color.fromARGB(255, 30, 30, 45),
                        Color.fromARGB(255, 30, 30, 45),
                      ]
                    : const [Color(0xFFF6F9FF), Color(0xFFE0E7F3)],
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
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(20, 255, 255, 255),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33090F23),
              blurRadius: 18,
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
                border: Border.all(
                  color: const Color.fromARGB(20, 255, 255, 255),
                ),
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

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    Key? key,
    required this.username,
    required this.isDark,
    required this.onSettings,
    required this.onLogout,
  }) : super(key: key);

  final String username;
  final bool isDark;
  final VoidCallback onSettings;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFFB3B8D7)
        : const Color(0xFF475569);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: SizedBox(
        height: 65,
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
            const Spacer(),
            IconButton(
              tooltip: 'Settings',
              onPressed: onSettings,
              icon: Icon(Icons.settings, color: mutedTextColor),
            ),
            IconButton(
              tooltip: 'Выйти',
              onPressed: () async {
                await onLogout();
              },
              icon: Icon(Icons.logout_rounded, color: mutedTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeonAvatar extends StatelessWidget {
  const _NeonAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 33,
      height: 33,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDADADA), width: 2),
      ),
      child: const CircleAvatar(
        backgroundColor: Color(0xFF14191E),
        child: Icon(
          Icons.person,
          size: 22,
          color: Color.fromARGB(255, 219, 219, 219),
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

class _NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final center = w / 2;

    const notchRadius = 40.0;
    const notchDepth = 35.0;

    path.lineTo(center - notchRadius - 30, 0);

    path.quadraticBezierTo(
      center - notchRadius,
      0,
      center - notchRadius,
      notchDepth,
    );

    path.arcToPoint(
      Offset(center + notchRadius, notchDepth),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    path.quadraticBezierTo(
      center + notchRadius,
      0,
      center + notchRadius + 30,
      0,
    );

    path.lineTo(w, 0);
    path.lineTo(w, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_) => false;
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
    final gradient = isDark
        ? const [Color(0xFF485ACD), Color(0xFF3A1C7C)]
        : const [Color(0xFF7999FF), Color(0xFF6085FF)];

    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 25,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _NavBarClipper(),
              child: Container(
                height: 85,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF485ACD), Color(0xFF3A1C7C)]
                        : const [Color(0xFF7999FF), Color(0xFF6085FF)],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 45,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavIcon(
                  icon: Icons.home_rounded,
                  active: index == 0,
                  onTap: () => onChanged(0),
                  activeColor: Colors.white,
                ),
                _NavIcon(
                  icon: Icons.pie_chart_rounded,
                  active: index == 1,
                  onTap: () => onChanged(1),
                  activeColor: Colors.white,
                ),
                const SizedBox(width: 80),
                _NavIcon(
                  icon: Icons.settings_rounded,
                  active: index == 2,
                  onTap: () => onChanged(2),
                  activeColor: Colors.white,
                ),
                _NavIcon(
                  icon: Icons.table_rows_rounded,
                  active: index == 3,
                  onTap: () => onChanged(3),
                  activeColor: Colors.white,
                ),
              ],
            ),
          ),

          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onQrTap,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4D6CFF).withOpacity(.6),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                  size: 30,
                ),
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
