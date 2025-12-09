part of '../home_page.dart';

class _QrSheet extends StatelessWidget {
  const _QrSheet({required this.address});

  final String? address;

  @override
  Widget build(BuildContext context) {
    final fallback = address ?? '0x0000...0000';
    return _SheetContainer(
      title: 'Мой QR',
      subtitle: 'Покажите для быстрого сканирования',
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2645), Color(0xFF12162B)],
              ),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.qr_code_rounded,
              size: 150,
              color: Color(0xFF80B7FF),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Сканируйте, чтобы поделиться адресом',
            style: GoogleFonts.inter(color: const Color(0xFF9AA5CC)),
          ),
          const SizedBox(height: 10),
          SelectableText(
            fallback,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
