part of '../home/home_page.dart';

class _PopularCoinsSheet extends StatelessWidget {
  const _PopularCoinsSheet();

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Популярные криптовалюты',
      subtitle: 'Трендовые активы за 24 часа',
      child: FutureBuilder<List<Coin>>(
        future: CoinService.fetchTopCoins(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Ошибка загрузки курсов',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            );
          }
          final coins = snap.data ?? <Coin>[];
          return Column(
            children: coins.map((coin) {
              final isNegative = coin.change24h < 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1628),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isNegative
                          ? const Color(0x20FF7A7A)
                          : const Color(0x2037E6A9),
                      child: Text(
                        coin.symbol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coin.symbol,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${coin.formattedPrice} USD',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF7E89B4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isNegative
                            ? const Color(0x33FF7A7A)
                            : const Color(0x1A53F3C3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isNegative
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 14,
                            color: isNegative
                                ? const Color(0xFFFF7A7A)
                                : const Color(0xFF53F3C3),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            coin.formattedChange,
                            style: GoogleFonts.inter(
                              color: isNegative
                                  ? const Color(0xFFFF7A7A)
                                  : const Color(0xFF53F3C3),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// Note: coin model moved to models/coin.dart
