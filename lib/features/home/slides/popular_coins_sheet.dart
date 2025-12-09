part of '../home_page.dart';

class _PopularCoinsSheet extends StatelessWidget {
  const _PopularCoinsSheet();

  @override
  Widget build(BuildContext context) {
    final coins = [
      ('ATX', '+4.2%', '125.40'),
      ('BNB', '-1.1%', '563.10'),
      ('ETH', '+2.8%', '3,205.00'),
      ('SOL', '+0.6%', '145.70'),
    ];
    return _SheetContainer(
      title: 'Популярные криптовалюты',
      subtitle: 'Трендовые активы за 24 часа',
      child: Column(
        children: coins
            .map(
              (coin) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF151B32),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0x332E9AFF),
                      child: Text(
                        coin.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coin.$1,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${coin.$3} USD',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF7E89B4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      coin.$2,
                      style: GoogleFonts.inter(
                        color: coin.$2.startsWith('-')
                            ? const Color(0xFFFF7A7A)
                            : const Color(0xFF53F3C3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
