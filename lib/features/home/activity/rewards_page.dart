part of '../home_page.dart';

// ─── Referral condition model ─────────────────────────────────────────────────
class _ReferralCondition {
  const _ReferralCondition(this.xp, this.description);
  final String xp;
  final String description;
}

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage>
    with TickerProviderStateMixin {
  int _tab = 2;
  late final TabController _innerTab;

  late final NewsService _newsService;
  late Future<NewsFeed> _newsFuture;

  // Daily bonus timer
  Timer? _bonusTimer;
  Duration _bonusCountdown = const Duration(hours: 8, minutes: 23, seconds: 45);
  bool _bonusClaimed = false;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 5, vsync: this);
    _newsService = NewsService();
    _newsFuture = _newsService.fetchCointelegraph(limit: 15);
    _startBonusTimer();
  }

  void _startBonusTimer() {
    _bonusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_bonusCountdown.inSeconds > 0) {
          _bonusCountdown -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _bonusTimer?.cancel();
    _innerTab.dispose();
    _newsService.dispose();
    super.dispose();
  }

  Future<void> _openAiAgentChatPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AiAgentChatPage()));
  }

  void _handleTabChange(int value) {
    if (value == 0) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      return;
    }
    if (value == 1) {
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
      Navigator.of(context).pushNamed('/history');
    }
  }

  Future<void> _refreshNews() async {
    setState(() {
      _newsFuture = _newsService.fetchCointelegraph(limit: 15);
    });
    try {
      await _newsFuture;
    } catch (_) {}
  }

  String _formatPublishedAt(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _openNewsUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Некорректная ссылка')));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку')),
      );
    }
  }

  Widget _buildNewsItemCard({
    required NewsItem item,
    required int index,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final dateText = _formatPublishedAt(item.publishedAt);
    const accents = [
      [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
      [Color(0xFF10B981), Color(0xFF34D399)],
      [Color(0xFFEC4899), Color(0xFFDB2777)],
      [Color(0xFFF59E0B), Color(0xFFD97706)],
      [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      [Color(0xFF38BDF8), Color(0xFF3B82F6)],
    ];
    final accent = accents[index % accents.length];
    return GestureDetector(
      onTap: () => _openNewsUrl(item.url),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0x0DFFFFFF),
          border: Border.all(color: accent[0].withValues(alpha: .12), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent[0], accent[1]],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateText,
                          style: GoogleFonts.inter(
                            color: secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'Читать',
                              style: GoogleFonts.inter(
                                color: accent[0],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: accent[0],
                              size: 12,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        color: primaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    if (item.summary.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.summary.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: secondaryTextColor,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final wallet = WalletScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark
        ? const Color(0xFF9AA8D1)
        : const Color(0xFF475569);

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          AnimatedNeonBackground(isDark: isDark),
          if (isDark) ...[
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
          ],
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: HomeTopBar(
                    username: auth.currentUser?.username ?? 'Wallet',
                    isDark: isDark,
                    onWallets: () => showWalletsSheet<void>(context),
                    onSettings: () async {
                      await Navigator.pushNamed(context, '/settings');
                    },
                    onLogout: () async {
                      wallet.clearDevProfile();
                      await auth.logout();
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ),
                // ── Inner tab bar (scrollable, 5 tabs) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x1AFFFFFF)
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x22FFFFFF)
                            : const Color(0x22000000),
                      ),
                    ),
                    child: TabBar(
                      controller: _innerTab,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.all(4),
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4D6CFF,
                            ).withValues(alpha: .4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: secondaryTextColor,
                      tabs: const [
                        Tab(text: 'Награды'),
                        Tab(text: 'Задания'),
                        Tab(text: 'Стейкинг'),
                        Tab(text: 'Рефералы'),
                        Tab(text: 'Новости'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // ── Content ──
                Expanded(
                  child: TabBarView(
                    controller: _innerTab,
                    children: [
                      _buildRewardsTab(primaryTextColor, secondaryTextColor),
                      _buildTasksTab(primaryTextColor, secondaryTextColor),
                      _buildStakingTab(primaryTextColor, secondaryTextColor),
                      _buildReferralsTab(primaryTextColor, secondaryTextColor),
                      _buildNewsTab(primaryTextColor, secondaryTextColor),
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
        onQrTap: _openAiAgentChatPage,
        isDark: isDark,
      ),
    );
  }

  // ── Tab 0: Rewards ────────────────────────────────────────────────────────
  Widget _buildRewardsTab(Color primaryTextColor, Color secondaryTextColor) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 190),
      children: [
        const _RewardsIllustration(),
        const SizedBox(height: 20),
        Row(
          children: const [
            Expanded(
              child: _StatCard(title: 'Уровень', value: '100 XP to\nБронзовый'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(title: 'XP Баланс', value: '0 XP'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _LevelProgressBar(
          current: 0,
          target: 100,
          levelName: 'Бронзовый',
        ),
        const SizedBox(height: 18),
        _DailyBonusCard(
          countdown: _bonusCountdown,
          claimed: _bonusClaimed,
          formatted: _formatCountdown(_bonusCountdown),
          onClaim: (!_bonusClaimed && _bonusCountdown.inSeconds == 0)
              ? () => setState(() => _bonusClaimed = true)
              : null,
        ),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Достижения',
          subtitle: 'Разблокируй бейджи за активность',
        ),
        const SizedBox(height: 12),
        const _AchievementsGrid(),
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
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _RewardCard(item: _RewardItem.samples[i]),
          ),
        ),
        const SizedBox(height: 18),
        Row(
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
    );
  }

  // ── Tab 1: Tasks ──────────────────────────────────────────────────────────
  Widget _buildTasksTab(Color primaryTextColor, Color secondaryTextColor) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
      children: [
        Text(
          'Задания',
          style: GoogleFonts.inter(
            color: primaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Выполняй квесты и получай XP',
          style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Text(
          'Ежедневные',
          style: GoogleFonts.inter(
            color: primaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final q in _QuestItem.daily) ...[
          _QuestCard(quest: q),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        Text(
          'Еженедельные',
          style: GoogleFonts.inter(
            color: primaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final q in _QuestItem.weekly) ...[
          _QuestCard(quest: q),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ── Tab 2: Staking ────────────────────────────────────────────────────────
  Widget _buildStakingTab(Color primaryTextColor, Color secondaryTextColor) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
      children: [
        Text(
          'Стейкинг',
          style: GoogleFonts.inter(
            color: primaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Зарабатывай на своих активах',
          style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13),
        ),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Всего в стейкинге',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF9AA8D1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '0.00 ETH',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Застейкать',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Доступные пулы',
          style: GoogleFonts.inter(
            color: primaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final pool in _StakingPool.samples) ...[
          _StakingPoolCard(pool: pool),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        Text(
          'Активные позиции',
          style: GoogleFonts.inter(
            color: primaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            children: [
              const Icon(
                Icons.inbox_rounded,
                color: Color(0xFF9AA8D1),
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'Нет активных позиций',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9AA8D1),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 3: Referrals ──────────────────────────────────────────────────────
  Widget _buildReferralsTab(Color primaryTextColor, Color secondaryTextColor) {
    const conditions = [
      _ReferralCondition('50 XP', 'за каждого приглашённого пользователя'),
      _ReferralCondition('100 XP', 'если друг выполнит первую транзакцию'),
      _ReferralCondition(
        '200 XP',
        'за каждого пользователя с уровнем Бронзовый+',
      ),
    ];
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
      children: [
        Text(
          'Рефералы',
          style: GoogleFonts.inter(
            color: primaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Приглашай друзей — получай XP',
          style: GoogleFonts.inter(color: secondaryTextColor, fontSize: 13),
        ),
        const SizedBox(height: 16),
        // Referral link card
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Твоя реферальная ссылка',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9AA8D1),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1535),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x224D6CFF)),
                      ),
                      child: Text(
                        'https://atx.app/ref/you',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9FB1FF),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        const ClipboardData(text: 'https://atx.app/ref/you'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ссылка скопирована')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
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
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(
              child: _StatCard(title: 'Приглашено', value: '0'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(title: 'Заработано XP', value: '0 XP'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Условия программы',
          style: GoogleFonts.inter(
            color: primaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (int i = 0; i < conditions.length; i++) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A2E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        conditions[i].xp,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF7CF8A5),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        conditions[i].description,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9AA8D1),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (i < conditions.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            children: [
              const Icon(
                Icons.group_add_rounded,
                color: Color(0xFF9AA8D1),
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'Нет приглашённых пользователей',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9AA8D1),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 4: News ───────────────────────────────────────────────────────────
  Widget _buildNewsTab(Color primaryTextColor, Color secondaryTextColor) {
    return FutureBuilder<NewsFeed>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
            children: [
              _newsHeader(primaryTextColor, secondaryTextColor),
              const SizedBox(height: 18),
              const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
            children: [
              _newsHeader(primaryTextColor, secondaryTextColor),
              const SizedBox(height: 14),
              GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Не удалось загрузить новости',
                      style: GoogleFonts.inter(
                        color: primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: GoogleFonts.inter(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: _refreshNews,
                        child: const Text('Повторить'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final items = snapshot.data?.items ?? const <NewsItem>[];
        return RefreshIndicator(
          onRefresh: _refreshNews,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
            children: [
              _newsHeader(primaryTextColor, secondaryTextColor),
              const SizedBox(height: 14),
              if (items.isEmpty)
                GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Пока нет новостей',
                    style: GoogleFonts.inter(
                      color: primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                for (int i = 0; i < items.length; i++) ...[
                  _buildNewsItemCard(
                    item: items[i],
                    index: i,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _newsHeader(Color primaryTextColor, Color secondaryTextColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Крипто-новости',
                style: GoogleFonts.inter(
                  color: primaryTextColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.rss_feed_rounded,
                    size: 12,
                    color: Color(0xFFFF6B35),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cointelegraph RU',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9AA8D1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _refreshNews,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF9AA8D1),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rewards tab widgets
// ─────────────────────────────────────────────────────────────────────────────

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
                  color: const Color(0xFF34D399).withValues(alpha: .4),
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
                      color: item.gradient.first.withValues(alpha: .4),
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
                      color: const Color(0xFF0F172A).withValues(alpha: .75),
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
                  'Получите доступ к закрытым бонусам и\n'
                  'персональным предложениям.',
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

// ─────────────────────────────────────────────────────────────────────────────
// Rewards tab — new widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LevelProgressBar extends StatelessWidget {
  const _LevelProgressBar({
    required this.current,
    required this.target,
    required this.levelName,
  });

  final int current;
  final int target;
  final String levelName;

  @override
  Widget build(BuildContext context) {
    final pct = (current / target).clamp(0.0, 1.0);
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Прогресс до $levelName',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9AA8D1),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$current / $target XP',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (ctx, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B233F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: constraints.maxWidth * pct,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4D6CFF), Color(0xFF34D399)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4D6CFF).withValues(alpha: .5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DailyBonusCard extends StatelessWidget {
  const _DailyBonusCard({
    required this.countdown,
    required this.claimed,
    required this.formatted,
    required this.onClaim,
  });

  final Duration countdown;
  final bool claimed;
  final String formatted;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final canClaim = onClaim != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: canClaim
              ? [
                  const Color(0xFF4D6CFF).withValues(alpha: .2),
                  const Color(0xFF34D399).withValues(alpha: .15),
                ]
              : [const Color(0xFF1B233F), const Color(0xFF1B233F)],
        ),
        border: Border.all(
          color: canClaim
              ? const Color(0xFF4D6CFF).withValues(alpha: .4)
              : const Color(0xFF2A3550),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: canClaim
                  ? const LinearGradient(
                      colors: [Color(0xFF4D6CFF), Color(0xFF34D399)],
                    )
                  : null,
              color: canClaim ? null : const Color(0xFF2A3550),
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: canClaim ? Colors.white : const Color(0xFF4A5578),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ежедневный бонус',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  claimed
                      ? 'Уже получен сегодня'
                      : canClaim
                      ? 'Доступен прямо сейчас!'
                      : 'Следующий через $formatted',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9AA8D1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onClaim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: canClaim
                    ? const LinearGradient(
                        colors: [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
                      )
                    : null,
                color: canClaim ? null : const Color(0xFF2A3550),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                claimed
                    ? '✓'
                    : canClaim
                    ? '+10 XP'
                    : formatted,
                style: GoogleFonts.inter(
                  color: canClaim ? Colors.white : const Color(0xFF4A5578),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  const _Achievement({
    required this.icon,
    required this.label,
    required this.unlocked,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final bool unlocked;
  final List<Color>? gradient;

  static const samples = [
    _Achievement(
      icon: Icons.send_rounded,
      label: 'Первая\nтранзакция',
      unlocked: false,
    ),
    _Achievement(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Пополнил\nкошелёк',
      unlocked: false,
    ),
    _Achievement(
      icon: Icons.newspaper_rounded,
      label: 'Прочитал\nновость',
      unlocked: false,
    ),
    _Achievement(
      icon: Icons.star_rounded,
      label: '5 транзакций',
      unlocked: false,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    _Achievement(
      icon: Icons.group_rounded,
      label: 'Первый\nреферал',
      unlocked: false,
      gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    ),
    _Achievement(
      icon: Icons.local_fire_department_rounded,
      label: '7 дней подряд',
      unlocked: false,
      gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
    ),
  ];
}

class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: [
        for (final a in _Achievement.samples) _AchievementTile(achievement: a),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final _Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final grad =
        achievement.gradient ??
        [const Color(0xFF4D6CFF), const Color(0xFF2F4BFF)];
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Opacity(
        opacity: achievement.unlocked ? 1.0 : 0.35,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: grad),
              ),
              child: Icon(achievement.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tasks tab widgets
// ─────────────────────────────────────────────────────────────────────────────

class _QuestItem {
  const _QuestItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.xp,
    required this.done,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String description;
  final int xp;
  final bool done;
  final List<Color> gradient;

  static const daily = [
    _QuestItem(
      icon: Icons.send_rounded,
      title: 'Отправь транзакцию',
      description: 'Отправь любую сумму на адрес',
      xp: 20,
      done: false,
      gradient: [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
    ),
    _QuestItem(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Пополни кошелёк',
      description: 'Получи любую сумму на свой адрес',
      xp: 15,
      done: false,
      gradient: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    _QuestItem(
      icon: Icons.newspaper_rounded,
      title: 'Проверь новости',
      description: 'Открой вкладку Новости',
      xp: 5,
      done: false,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
    _QuestItem(
      icon: Icons.login_rounded,
      title: 'Войди в приложение',
      description: 'Ты уже здесь — задание выполнено!',
      xp: 5,
      done: true,
      gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    ),
  ];

  static const weekly = [
    _QuestItem(
      icon: Icons.repeat_rounded,
      title: 'Сделай 5 транзакций',
      description: 'Отправь или получи 5 переводов за неделю',
      xp: 100,
      done: false,
      gradient: [Color(0xFFEC4899), Color(0xFFDB2777)],
    ),
    _QuestItem(
      icon: Icons.group_add_rounded,
      title: 'Пригласи друга',
      description: 'Поделись реферальной ссылкой',
      xp: 50,
      done: false,
      gradient: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
    ),
    _QuestItem(
      icon: Icons.swap_horiz_rounded,
      title: 'Выполни своп',
      description: 'Обменяй один токен на другой',
      xp: 75,
      done: false,
      gradient: [Color(0xFF22C55E), Color(0xFF16A34A)],
    ),
  ];
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest});

  final _QuestItem quest;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: quest.done
                  ? null
                  : LinearGradient(colors: quest.gradient),
              color: quest.done ? const Color(0xFF1E3A2E) : null,
            ),
            child: Icon(
              quest.done ? Icons.check_circle_rounded : quest.icon,
              color: quest.done ? const Color(0xFF7CF8A5) : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: GoogleFonts.inter(
                    color: quest.done ? const Color(0xFF9AA8D1) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: quest.done ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFF9AA8D1),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  quest.description,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8E99C0),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: quest.done
                  ? const Color(0xFF1E3A2E)
                  : const Color(0xFF0D1535),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: quest.done
                    ? const Color(0xFF7CF8A5).withValues(alpha: .3)
                    : const Color(0xFF4D6CFF).withValues(alpha: .3),
              ),
            ),
            child: Text(
              '+${quest.xp} XP',
              style: GoogleFonts.inter(
                color: quest.done
                    ? const Color(0xFF7CF8A5)
                    : const Color(0xFF9FB1FF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staking tab widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StakingPool {
  const _StakingPool({
    required this.token,
    required this.apy,
    required this.duration,
    required this.gradient,
    required this.min,
  });

  final String token;
  final String apy;
  final String duration;
  final List<Color> gradient;
  final String min;

  static const samples = [
    _StakingPool(
      token: 'ETH',
      apy: '4.5%',
      duration: '30 дней',
      min: 'от 0.01 ETH',
      gradient: [Color(0xFF5782FF), Color(0xFF4D6CFF)],
    ),
    _StakingPool(
      token: 'USDT',
      apy: '8.2%',
      duration: '90 дней',
      min: 'от 10 USDT',
      gradient: [Color(0xFF3DD5D0), Color(0xFF22C55E)],
    ),
    _StakingPool(
      token: 'BTC',
      apy: '2.8%',
      duration: '60 дней',
      min: 'от 0.001 BTC',
      gradient: [Color(0xFFF7C344), Color(0xFFD97706)],
    ),
  ];
}

class _StakingPoolCard extends StatelessWidget {
  const _StakingPoolCard({required this.pool});

  final _StakingPool pool;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: pool.gradient),
            ),
            child: Center(
              child: Text(
                pool.token,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pool.token,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${pool.duration} · ${pool.min}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8E99C0),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pool.apy,
                style: GoogleFonts.inter(
                  color: const Color(0xFF7CF8A5),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'APY',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9AA8D1),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Войти',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
