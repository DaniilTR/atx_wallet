// lib/features/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'activity/market/coin_detail_page.dart';
import 'activity/market/models/coin.dart';
import 'activity/market/services/coin_service.dart';
import 'activity/qr_page.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/wallet_scope.dart';
import '../../services/auth_scope.dart';
import '../../services/config.dart';
import '../auth/widgets/animated_neon_background.dart';
import '../auth/widgets/glass_card.dart';
import 'widgets/bottom_nav.dart';

part 'slides/sheet_container.dart';
part 'slides/send_sheet.dart';
part 'slides/receive_sheet.dart';
part 'slides/buy_sheet.dart';
part 'slides/swap_sheet.dart';
part 'slides/wallets/wallets_sheet.dart';
part 'slides/wallets/add_wallet_sheet.dart';
part 'activity/market/market_screen.dart';
part 'activity/rewards_page.dart';
part 'activity/send_flow_page.dart';
part 'slides/labeled_field.dart';
part 'slides/primary_button.dart';
part 'slides/info_chip.dart';
part 'slides/swap_card.dart';

class HomeRouteArgs {
  const HomeRouteArgs({required this.userId});

  final String userId;
}

class SendSheet extends StatelessWidget {
  const SendSheet({required this.address, this.initialRecipient, super.key});

  final String? address;
  final String? initialRecipient;

  @override
  Widget build(BuildContext context) {
    return _SendSheet(address: address, initialRecipient: initialRecipient);
  }
}

const Map<String, Color> _tokenColors = <String, Color>{
  'ETH': Color(0xFF5782FF),
  'USDT': Color(0xFF3DD5D0),
  'BTC': Color(0xFFF7C344),
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

  Future<void> _openSendFlow({String? recipient}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SendFlowPage(initialRecipient: recipient),
      ),
    );
  }

  Future<void> _openReceiveSheet() =>
      _showNeonSheet(_ReceiveSheet(address: _currentAddress));

  Future<void> _openBuySheet() => _showNeonSheet(const _BuySheet());

  Future<void> _openSwapSheet() => _showNeonSheet(const _SwapSheet());

  Future<void> _openHistoryPage() async {
    await Navigator.of(context).pushNamed('/history');
  }

  Future<void> _openQrPage() async {
    final scanned = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => QrPage(address: _currentAddress)),
    );
    if (!mounted) return;
    if (scanned != null) {
      await _openSendFlow(recipient: scanned);
    }
  }

  String? get _currentAddress {
    final wallet = WalletScope.of(context);
    final profile = wallet.activeProfile;
    return profile?.addressHex;
  }

  void _handleTabChange(int value) {
    if (value == 2) {
      Navigator.of(context).pushReplacementNamed('/rewards');
      return;
    }
    if (value == 1) {
      setState(() => _tab = value);
      Navigator.of(context).pushReplacementNamed('/market');
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
    final balances = wallet.balances;
    final profile = wallet.activeProfile;
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
      body: Stack(
        children: [
          AnimatedNeonBackground(isDark: isDark),
          if (isDark) ...[
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
                      username: username,
                      isDark: isDark,
                      onWallets: () => showWalletsSheet<void>(context),
                      onSettings: () =>
                          Navigator.pushNamed(context, '/settings'),
                      onLogout: () async {
                        wallet.clearDevProfile();
                        await auth.logout();
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, '/start');
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
                              backgroundColor: isDark
                                  ? const Color(0xFF1C1F33)
                                  : Colors.white,
                              content: Text(
                                'Address copied',
                                style: GoogleFonts.inter(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      _ActionsRow(
                        isDark: isDark,
                        onSend: _openSendFlow,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDark
                                            ? const Color(0xFFDDE1FF)
                                            : const Color(0xFF4C6BFF),
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

    final borderTint = isDark
        ? Colors.white.withOpacity(0.22)
        : Colors.black.withOpacity(0.08);

    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFFB7C4EA)
        : const Color(0xFF475569);

    final totalUsd = balances.totalUsd;
    final loading = balances.isLoading;
    final updatedLabel = _formatTimestamp(balances.updatedAt);

    final addressPanelBg = isDark
        ? const Color(0xFF3A3F52)
        : Colors.white.withOpacity(0.72);
    final addressPanelShadow = isDark
        ? const Color(0x33090F23)
        : Colors.black.withOpacity(0.10);
    final addressLabelColor = primaryTextColor;
    final addressValueColor = isDark ? const Color(0xFFD3DAED) : mutedTextColor;
    final copyBg = isDark
        ? Colors.white.withOpacity(.08)
        : Colors.black.withOpacity(.04);
    final copyBorder = isDark
        ? Colors.white.withOpacity(.2)
        : Colors.black.withOpacity(.08);
    final copyIconColor = primaryTextColor;

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
                          color: isDark
                              ? const Color(0xFFE8EEFF)
                              : const Color(0xFF0F172A),
                          fontSize: 13,
                          letterSpacing: .3,
                        ),
                      ),
                      const Spacer(),
                      _GrowthPill(
                        value: loading ? 'Обновляем' : updatedLabel,
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
                                  ' USD '
                            : '—',
                        style: GoogleFonts.inter(
                          color: primaryTextColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
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
                    color: addressPanelBg,
                    boxShadow: [
                      BoxShadow(
                        color: addressPanelShadow,
                        blurRadius: 24,
                        offset: const Offset(0, 18),
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
                                color: addressLabelColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayAddress ?? '—',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: addressValueColor,
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
                            color: copyBg,
                            border: Border.all(color: copyBorder),
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            color: copyIconColor,
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
                    : const [
                        Color.fromARGB(255, 228, 230, 236),
                        Color.fromARGB(255, 208, 211, 216),
                      ],
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
              color: isDark
                  ? const Color.fromARGB(255, 186, 188, 197)
                  : const Color(0xFF0F172A),
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
  const _AssetTile({required this.balance, required this.color});

  final AssetBalance balance;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark
        ? Colors.white.withOpacity(0.85)
        : const Color(0xFF475569);
    final tertiaryTextColor = isDark
        ? const Color(0xFF9FB3D8)
        : const Color(0xFF475569);
    final amountLabel =
        '${_formatNumber(balance.amount, precision: 6)} ${balance.token.symbol}';
    final usdValue = balance.usdValue;
    final tokenPriceUsd = balance.priceUsd;
    final valueLabel = usdValue == null
        ? '—'
        : '\$${_formatNumber(usdValue, precision: 2)}';
    final secondaryLabel = amountLabel;

    return GlassCard(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CoinDetailPage(
                symbol: balance.token.symbol,
                name: balance.token.name,
                coinId: balance.token.coinGeckoId,
                priceUsd: tokenPriceUsd,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color.fromARGB(19, 255, 255, 255)
                : const Color.fromARGB(255, 255, 255, 255).withOpacity(0.03),
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark
                ? const [
                    BoxShadow(
                      color: Color(0x33090F23),
                      blurRadius: 12,
                      offset: Offset(0, 8),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color.fromARGB(164, 255, 255, 255),
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
                    color: isDark
                        ? const Color.fromARGB(60, 255, 255, 255)
                        : const Color.fromARGB(20, 255, 255, 255),
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
                        color: primaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      amountLabel,
                      style: GoogleFonts.inter(
                        color: secondaryTextColor,
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
                      color: primaryTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    secondaryLabel,
                    style: GoogleFonts.inter(
                      color: tertiaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    this.onWallets,
    required this.onSettings,
    required this.onLogout,
  }) : super(key: key);

  final String username;
  final bool isDark;
  final VoidCallback? onWallets;
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
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onWallets,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      username,
                      style: GoogleFonts.inter(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: mutedTextColor,
                    ),
                  ],
                ),
              ),
            ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 33,
      height: 33,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? const Color(0xFFDADADA)
              : Colors.black.withOpacity(0.12),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: isDark ? const Color(0xFF14191E) : Colors.white,
        child: Icon(
          Icons.person,
          size: 22,
          color: isDark
              ? const Color.fromARGB(255, 219, 219, 219)
              : const Color(0xFF0F172A),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark
        ? const Color.fromARGB(178, 255, 255, 255)
        : const Color.fromARGB(195, 0, 0, 0);
    final iconColor = isDark
        ? const Color.fromARGB(211, 255, 255, 255)
        : const Color.fromARGB(197, 0, 0, 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          Icon(Icons.trending_up, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
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
