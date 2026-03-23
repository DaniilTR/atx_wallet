// home/slides/receive_sheet.dart

part of '../home_page.dart';

class _ReceiveSheet extends StatelessWidget {
  const _ReceiveSheet({required this.address});

  final String? address;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFFB5BEDF)
        : const Color(0xFF475569);

    final wallet = WalletScope.of(context);
    final evmAddress = address;
    final btcAddress = wallet.bitcoinAddress;

    final evmFallback = evmAddress ?? '0x0000...0000';
    final btcFallback = btcAddress ?? '—';

    return _SheetContainer(
      title: 'Получить средства',
      subtitle: 'Покажите QR или поделитесь адресом',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark
                  ? const Color(0xFF14191E)
                  : Colors.black.withValues(alpha: 0.03),
              border: Border.all(
                color: isDark
                    ? const Color(0x33FFFFFF)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            alignment: Alignment.center,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = constraints.maxWidth * 0.9;
                final qrSize = side * 0.8;
                return SizedBox(
                  width: qrSize,
                  height: qrSize,
                  child: QrImageView(
                    data: evmFallback,
                    backgroundColor: Colors.transparent,
                    size: qrSize,
                    gapless: false,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF80B7FF),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF80B7FF),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ethereum (ETH / USDT)',
              style: GoogleFonts.inter(color: mutedTextColor, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            evmFallback,
            style: GoogleFonts.inter(
              color: primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: 'Скопировать ETH адрес',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: evmFallback));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Адрес скопирован', style: GoogleFonts.inter()),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Bitcoin (BTC)',
              style: GoogleFonts.inter(color: mutedTextColor, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            btcFallback,
            style: GoogleFonts.inter(
              color: primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: 'Скопировать BTC адрес',
            onPressed: btcAddress == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: btcAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Адрес скопирован',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
