part of '../home/home_page.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _tab = 1;

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

  Future<void> _openHistoryPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HistoryPage()));
  }

  Future<void> _openQrPage() async {
    final scanned = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => QrPage(address: _currentAddress)),
    );
    if (!mounted) return;
    if (scanned != null) {
      await _showNeonSheet<void>(
        _SendSheet(address: _currentAddress, initialRecipient: scanned),
      );
    }
  }

  String? get _currentAddress {
    final wallet = WalletScope.of(context);
    final args = ModalRoute.of(context)?.settings.arguments as HomeRouteArgs?;
    final profile = wallet.activeProfile ?? args?.devProfile;
    return profile?.addressHex;
  }

  void _handleTabChange(int value) {
    if (value == 0) {
      Navigator.of(context).pop();
      return;
    }
    if (value == 2) {
      Navigator.pushNamed(context, '/settings');
      return;
    }
    setState(() => _tab = value);
    if (value == 3) {
      _openHistoryPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final wallet = WalletScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final scaffoldBg = theme.scaffoldBackgroundColor;

    return Scaffold(
      extendBody: true,
      backgroundColor: scaffoldBg,
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
                const SizedBox(height: 16),
                Text(
                  'Список котировок',
                  style: GoogleFonts.inter(
                    color: primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Coin>>(
                  future: CoinService.fetchTopCoins(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Ошибка загрузки курсов. Проверьте интернет и попробуйте позже.',
                            style: GoogleFonts.inter(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    final coins = snap.data ?? <Coin>[];
                    return Column(
                      children: [
                        for (var i = 0; i < coins.length; i++) ...[
                          _MarketRow(coin: coins[i]),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onChanged: _handleTabChange,
        onQrTap: _openQrPage,
        isDark: isDark,
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.coin});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final isNegative = coin.change24h < 0;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CoinDetailPage(
              symbol: coin.symbol,
              name: coin.name,
              coinId: coin.id,
              priceUsd: coin.priceUsd,
              change24h: coin.change24h,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(20, 255, 255, 255),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF151B2D),
              child: Text(
                coin.symbol.substring(0, 1),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            SizedBox(
              width: 110,
              height: 38,
              child: (coin.sparkline != null && coin.sparkline!.length >= 2)
                  ? _Sparkline(
                      data: coin.sparkline!,
                      color: isNegative
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF31E6D2),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  coin.formattedPrice,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  coin.formattedChange,
                  style: GoogleFonts.inter(
                    color: isNegative
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF40C977),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(data: data, color: color),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2 || size.width == 0 || size.height == 0) return;
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final normalized = range == 0 ? 0.5 : (data[i] - minValue) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
