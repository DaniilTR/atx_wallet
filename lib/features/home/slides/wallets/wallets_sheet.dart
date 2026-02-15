part of '../../home_page.dart';

Future<T?> showWalletsSheet<T>(BuildContext context) {
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
        child: const _WalletsSheet(),
      ),
    ),
  );
}

class _WalletsSheet extends StatelessWidget {
  const _WalletsSheet();

  @override
  Widget build(BuildContext context) {
    final wallet = WalletScope.of(context);
    final auth = AuthScope.of(context);
    final userId = auth.currentUser?.id;

    final wallets = wallet.wallets;
    final activeId = wallet.activeProfile?.walletId;

    return _SheetContainer(
      title: 'Кошельки',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (wallets.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Пока нет добавленных кошельков',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF8E99C0),
                  fontSize: 13,
                ),
              ),
            )
          else
            for (final entry in wallets) ...[
              _WalletRow(
                profile: entry,
                isActive: entry.walletId == activeId,
                onTap: userId == null
                    ? null
                    : () async {
                        await wallet.switchActiveWallet(
                          userId: userId,
                          walletId: entry.walletId,
                        );
                        if (context.mounted) {
                          Navigator.of(context).maybePop();
                        }
                      },
              ),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 8),
          _PrimaryButton(
            label: ' Добавить кошелёк',
            onPressed: userId == null
                ? null
                : () async {
                    await showAddWalletSheet<void>(context);
                  },
          ),
        ],
      ),
    );
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  final DevWalletProfile profile;
  final bool isActive;
  final VoidCallback? onTap;

  String _short(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF14191E),
          border: Border.all(color: const Color(0x113D7CFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                color: const Color(0xFF14191E),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Color(0xFFB5BEDF),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.addressHex.isEmpty
                        ? '—'
                        : _short(profile.addressHex),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8E99C0),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isActive)
              const Icon(Icons.check_rounded, color: Color(0xFF34D399))
            else
              const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}
