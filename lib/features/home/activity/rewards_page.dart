part of '../home_page.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  int _tab = 2;

  late final NewsService _newsService;
  late Future<NewsFeed> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsService = NewsService();
    _newsFuture = _newsService.fetchCointelegraph(limit: 15);
  }

  @override
  void dispose() {
    _newsService.dispose();
    super.dispose();
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

  Future<void> _refreshNews() async {
    setState(() {
      _newsFuture = _newsService.fetchCointelegraph(limit: 15);
    });
    try {
      await _newsFuture;
    } catch (_) {
      // Ошибка отрисуется через FutureBuilder.
    }
  }

  String _formatPublishedAt(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
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
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final dateText = _formatPublishedAt(item.publishedAt);

    return GestureDetector(
      onTap: () => _openNewsUrl(item.url),
      child: GlassCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (item.summary.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.summary.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
            if (dateText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                dateText,
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
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
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  top: 69,
                  child: FutureBuilder<NewsFeed>(
                    future: _newsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
                          children: [
                            Text(
                              'Новости',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: primaryTextColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

                      final feed = snapshot.data;
                      final items = feed?.items ?? const <NewsItem>[];

                      return RefreshIndicator(
                        onRefresh: _refreshNews,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 190),
                          children: [
                            Text(
                              'Новости',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: primaryTextColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Cointelegraph RU',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: secondaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                              for (final item in items) ...[
                                _buildNewsItemCard(
                                  item: item,
                                  primaryTextColor: primaryTextColor,
                                  secondaryTextColor: secondaryTextColor,
                                ),
                                const SizedBox(height: 12),
                              ],
                          ],
                        ),
                      );
                    },
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
