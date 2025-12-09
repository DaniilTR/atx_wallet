part of '../home_page.dart';

class _BuySheet extends StatelessWidget {
  const _BuySheet();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('ATX', 'Пополнение через карту'),
      ('BNB', 'Перевод из Binance Pay'),
      ('USDT', 'P2P покупка'),
    ];
    return _SheetContainer(
      title: 'Купить актив',
      subtitle: 'Выберите удобный способ пополнения',
      child: Column(
        children: items
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C2444), Color(0xFF12162B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0x22FFFFFF)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0x4436C1FF),
                      child: Text(
                        item.$1,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            item.$2,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9CA9D4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF9FB0E1)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
