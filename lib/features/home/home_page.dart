import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/wallet_scope.dart';
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  Future<void> _showNeonSheet(Widget child) {
    return showModalBottomSheet<void>(
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

  Future<void> _openSendSheet() =>
      _showNeonSheet(_SendSheet(address: _currentAddress));

  Future<void> _openReceiveSheet() =>
      _showNeonSheet(_ReceiveSheet(address: _currentAddress));

  Future<void> _openBuySheet() => _showNeonSheet(const _BuySheet());

  Future<void> _openSwapSheet() => _showNeonSheet(const _SwapSheet());

  Future<void> _openPopularSheet() =>
      _showNeonSheet(const _PopularCoinsSheet());

  Future<void> _openHistorySheet() => _showNeonSheet(const _HistorySheet());

  Future<void> _openQrSheet() =>
      _showNeonSheet(_QrSheet(address: _currentAddress));

  String? get _currentAddress {
    final wallet = WalletScope.of(context);
    final args = ModalRoute.of(context)?.settings.arguments as HomeRouteArgs?;
    final profile = wallet.activeProfile ?? args?.devProfile;
    return profile?.addressHex;
  }

  void _handleTabChange(int value) {
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
    final args = ModalRoute.of(context)?.settings.arguments as HomeRouteArgs?;
    final profile = wallet.activeProfile ?? args?.devProfile;
    final address = profile?.addressHex;
    final username = auth.currentUser?.username ?? 'Wallet';
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color.fromARGB(255, 9, 24, 37),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        toolbarHeight: 78,
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
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFB3B8D7),
              ),
            ],
          ),
        ),
        actions: [
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
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFB3B8D7)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedNeonBackground(),
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
                  onCopy: () async {
                    if (address == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF1C1F33),
                          content: Text(
                            'Address is not ready yet',
                            style: GoogleFonts.inter(color: Colors.white),
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
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {},
                      child: Text(
                        'view all',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFB0BBCE),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _AssetTile(
                  name: 'Test BNB',
                  ticker: 'BNB',
                  color: Color(0xFF5782FF),
                  price: '3457.00',
                ),
                const SizedBox(height: 14),
                const _AssetTile(
                  name: 'ATX coin',
                  ticker: 'ATX',
                  color: Color(0xFF3DD5D0),
                  price: '4457.00',
                ),
                const SizedBox(height: 14),
                const _AssetTile(
                  name: 'Levcoin',
                  ticker: 'LEV',
                  color: Color(0xFFF7C344),
                  price: '512.00',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onChanged: _handleTabChange,
        onQrTap: _openQrSheet,
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.onCopy, this.address});
  final VoidCallback onCopy;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final displayAddress = address == null
        ? null
        : address!.length > 12
        ? '${address!.substring(0, 6)}...${address!.substring(address!.length - 4)}'
        : address!;
    final borderTint = Colors.white.withOpacity(0.22);

    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(),
        child: GlassCard(
          borderRadius: 36,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(49, 13, 18, 36),
                  Color.fromARGB(49, 25, 13, 53),
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
              24, // top
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
                      const _GrowthPill(value: '+15%'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '\$13450.00',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
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
        _ActionButton(
          icon: Icons.north_east_rounded,
          label: 'Отправить',
          onTap: onSend,
        ),
        _ActionButton(
          icon: Icons.south_rounded,
          label: 'Получить',
          onTap: onReceive,
        ),
        _ActionButton(
          icon: Icons.attach_money_rounded,
          label: 'Купить',
          onTap: onBuy,
        ),
        _ActionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Обменять',
          onTap: onSwap,
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
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF27305A), Color(0xFF171C33)],
              ),
              border: Border.all(color: const Color(0x33FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44090F25),
                  blurRadius: 22,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFFEFF2FF)),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: .1,
              color: const Color(0xFFCAD0E4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.name,
    required this.ticker,
    required this.color,
    required this.price,
  });

  final String name;
  final String ticker;
  final Color color;
  final String price;

  @override
  Widget build(BuildContext context) {
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
                    name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ticker,
                    style: GoogleFonts.inter(color: const Color(0xFF9FB3D8)),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 110,
              height: 34,
              child: CustomPaint(painter: _SparkPainter(color)),
            ),
            const SizedBox(width: 16),
            Text(
              price,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Path()
      ..moveTo(0, size.height * .75)
      ..cubicTo(
        size.width * .12,
        size.height * .55,
        size.width * .2,
        size.height * .85,
        size.width * .32,
        size.height * .4,
      )
      ..cubicTo(
        size.width * .42,
        size.height * .15,
        size.width * .55,
        size.height * .9,
        size.width * .68,
        size.height * .5,
      )
      ..cubicTo(
        size.width * .8,
        size.height * .2,
        size.width * .88,
        size.height * .65,
        size.width,
        size.height * .35,
      );

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = color.withOpacity(.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawPath(base, glow);
    canvas.drawPath(base, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeonAvatar extends StatelessWidget {
  const _NeonAvatar();

  @override
  Widget build(BuildContext context) {
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
      child: const CircleAvatar(
        backgroundColor: Color(0xFF1B2032),
        child: Icon(Icons.person, size: 18, color: Colors.white),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8DF2FF), Color(0xFF62D4F3)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x408CF0FF),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up, size: 16, color: Color(0xFF16273E)),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF16273E),
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
  });

  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onQrTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Stack(
        children: [
          Container(
            height: 110,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF485ACD), Color(0xFF3A1C7C)],
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
                                  activeColor: Colors.white,
                                ),
                                const SizedBox(width: 20),
                                _NavIcon(
                                  icon: Icons.table_rows_rounded,
                                  active: index == 3,
                                  onTap: () => onChanged(3),
                                  activeColor: Colors.white,
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
