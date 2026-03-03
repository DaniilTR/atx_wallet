part of '../home_page.dart';

class _ReceiveSheet extends StatelessWidget {
  const _ReceiveSheet({required this.address});

  final String? address;

  @override
  Widget build(BuildContext context) {
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
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF14191E),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 120,
              color: Color(0xFF6FE1F5),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ethereum (ETH / USDT)',
              style: GoogleFonts.inter(
                color: const Color(0xFFB5BEDF),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            evmFallback,
            style: GoogleFonts.inter(
              color: Colors.white,
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
              style: GoogleFonts.inter(
                color: const Color(0xFFB5BEDF),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            btcFallback,
            style: GoogleFonts.inter(
              color: Colors.white,
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
