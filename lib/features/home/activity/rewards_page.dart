part of '../home_page.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  int _tab = 3;

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
    await Navigator.of(context).pushNamed('/history');
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
    final profile = wallet.activeProfile;
    return profile?.addressHex;
  }

  void _handleTabChange(int value) {
    if (value == 0) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      return;
    }
    if (value == 1) {
      setState(() => _tab = value);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MarketScreen()),
      );
      return;
    }
    if (value == 2) {
      setState(() => _tab = value);
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

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          AnimatedNeonBackground(isDark: isDark),
          const Positioned(
            top: -30,
            right: -10,
            child: _GlowCircle(
              diameter: 220,
              color: Color(0xFF7D47FA),
              opacity: 0.75,
            ),
          ),
          const Positioned(
            top: 260,
            left: -80,
            child: _GlowCircle(
              diameter: 200,
              color: Color(0xFF60A5FA),
              opacity: 0.6,
            ),
          ),
          const Positioned(
            bottom: -40,
            right: -30,
            child: _GlowCircle(
              diameter: 220,
              color: Color(0xFF34D399),
              opacity: 0.7,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: HomeTopBar(
                      username: auth.currentUser?.username ?? 'Wallet',
                      isDark: isDark,
                      onWallets: () => showWalletsSheet<void>(context),
                      onSettings: () =>
                          Navigator.pushNamed(context, '/settings'),
                      onLogout: () async {
                        wallet.clearDevProfile();
                        await auth.logout();
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 69,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
                    children: [
                      Text(
                        'Rewards',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: primaryTextColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _RewardsIllustration(),
                      const SizedBox(height: 20),
                      Row(
                        children: const [
                          Expanded(
                            child: _StatCard(
                              title: 'Уровень',
                              value: '100 XP to\nБронзовый',
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(title: 'XP Баланс', value: '0 XP'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            child: _SectionTitle(
                              title: 'Redeem XP',
                              subtitle: 'Partner Benefits',
                            ),
                          ),
                          _RequirementChip(text: 'Бронзовый required'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 260,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _RewardItem.samples.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return _RewardCard(
                              item: _RewardItem.samples[index],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Expanded(
                            child: _SectionTitle(
                              title: 'Trust Alpha',
                              subtitle: 'Бронзовый required',
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFF9FB1FF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _TrustCard(),
                    ],
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

class _RewardsIllustration extends StatelessWidget {
  const _RewardsIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF22C55E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34D399).withOpacity(0.4),
                  blurRadius: 30,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.card_giftcard_rounded,
            color: Colors.white,
            size: 48,
          ),
          const Positioned(
            right: 8,
            top: 10,
            child: Icon(
              Icons.stars_rounded,
              color: Color(0xFF8B5CF6),
              size: 22,
            ),
          ),
          const Positioned(
            left: 18,
            bottom: 12,
            child: Icon(Icons.bolt_rounded, color: Color(0xFF60A5FA), size: 22),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF9AA8D1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            color: const Color(0xFF8E99C0),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B233F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x112E9AFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 14, color: Color(0xFFF5D98B)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFFF2E7C8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardItem {
  const _RewardItem({
    required this.title,
    required this.subtitle,
    required this.xpCost,
    required this.gradient,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String xpCost;
  final List<Color> gradient;
  final String? badge;

  static const samples = [
    _RewardItem(
      title: '\$50',
      subtitle: '\$50 hotel coupon\nwith Umy',
      xpCost: '800XP',
      gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
      badge: 'ENDED',
    ),
    _RewardItem(
      title: '40% OFF',
      subtitle: '40% off eSIM with\nTonMobile',
      xpCost: '400XP',
      gradient: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
      badge: 'ENDED',
    ),
    _RewardItem(
      title: 'Free Trial',
      subtitle: 'Free partner trial\n7 days access',
      xpCost: '100XP',
      gradient: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
  ];
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.item});

  final _RewardItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: item.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.gradient.first.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    item.title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (item.badge != null)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.badge!,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.subtitle,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.xpCost,
            style: GoogleFonts.inter(
              color: const Color(0xFF9FB1FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: item.badge == null ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A2E),
                foregroundColor: const Color(0xFF7CF8A5),
                disabledBackgroundColor: const Color(0xFF1E293B),
                disabledForegroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'View',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              ),
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alpha rewards',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Получите доступ к закрытым бонусам и\nперсональным предложениям.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8E99C0),
                    fontSize: 12,
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
