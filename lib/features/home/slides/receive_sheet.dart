part of '../home_page.dart';

class _ReceiveSheet extends StatelessWidget {
  const _ReceiveSheet({required this.address});

  final String? address;

  @override
  Widget build(BuildContext context) {
    final fallback = address ?? '0x0000...0000';
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
              color: const Color(0xFF161D34),
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
          SelectableText(
            fallback,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: 'Скопировать адрес',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: fallback));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Адрес скопирован', style: GoogleFonts.inter()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
