import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/wallet_scope.dart';
import '../../services/auth_scope.dart';
import 'home_route_args.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: 76,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 20),
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
            const SizedBox(width: 20),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Выйти',
            onPressed: () async {
              wallet.clearDevProfile();
              await auth.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFB3B8D7)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D1B32), Color(0xFF101537)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 160),
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
              const SizedBox(height: 28),
              const _ActionsRow(),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trends',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
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
              const SizedBox(height: 16),
              const _TrendTile(
                name: 'Litecoin',
                ticker: 'LTE',
                color: Color.fromARGB(136, 77, 124, 254),
                price: '3457.00',
              ),
              const SizedBox(height: 14),
              const _TrendTile(
                name: 'Dogecoin',
                ticker: 'DOGE',
                color: Color.fromARGB(134, 0, 209, 178),
                price: '4457.00',
              ),
              const SizedBox(height: 14),
              const _TrendTile(
                name: 'Levcoin',
                ticker: 'LEV',
                color: Color.fromARGB(129, 255, 201, 51),
                price: '512.00',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onChanged: (value) => setState(() => _tab = value),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.fromLTRB(23, 15, 23, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(179, 51, 34, 97),
            Color.fromARGB(179, 51, 33, 83),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x700F0725),
            blurRadius: 40,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total balance',
                style: GoogleFonts.inter(
                  color: const Color(0xFFE8DEFF),
                  fontSize: 14,
                ),
              ),
              const _GrowthPill(value: '+15%'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$13450.00',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2D1143), Color(0xFF1B0B27)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x33FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 16,
                  offset: Offset(0, 10),
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
                        'Your address',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFC7CCF1),
                          fontSize: 12,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayAddress ?? '—',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4F1D7A), Color(0xFF2D0A46)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x26FFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.copy_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow();

  static const List<_ActionData> _items = [
    _ActionData(Icons.north_east_rounded, 'Отправить'),
    _ActionData(Icons.south_rounded, 'Получить'),
    _ActionData(Icons.attach_money_rounded, 'Купить'),
    _ActionData(Icons.swap_horiz_rounded, 'Обменять'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _items
          .map(
            (item) => Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2F3561), Color(0xFF1A1F3C)],
                    ),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55090F25),
                        blurRadius: 20,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: const Color(0xFFEFF2FF)),
                ),
                const SizedBox(height: 10),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .1,
                    color: const Color(0xFFCAD0E4),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _ActionData {
  const _ActionData(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _TrendTile extends StatelessWidget {
  const _TrendTile({
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(.55), const Color(0xFF10132C)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x26FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55090F23),
            blurRadius: 36,
            offset: Offset(0, 22),
          ),
        ],
      ),
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
  const _BottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(height: 110, decoration: const BoxDecoration()),
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'lib/features/home/Vector 12.png',
                height: 115,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: SizedBox(
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      const SizedBox(width: 64),
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
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFDBC5FF), Color(0xFFB89BFF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xAA433071),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 30,
                      color: Color(0xFF1A1034),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
