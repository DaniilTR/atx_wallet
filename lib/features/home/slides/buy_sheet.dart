part of '../home_page.dart';

class _BuySheet extends StatelessWidget {
  const _BuySheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xFF14191E)
        : Colors.black.withOpacity(0.03);
    final borderColor = isDark
        ? const Color(0x22FFFFFF)
        : Colors.black.withOpacity(0.08);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark
        ? const Color(0xFF9CA9D4)
        : const Color(0xFF475569);

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
                  color: cardBg,
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: cardBg,
                      child: Text(
                        item.$1,
                        style: TextStyle(color: primaryTextColor),
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
                              color: primaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            item.$2,
                            style: GoogleFonts.inter(
                              color: mutedTextColor,
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
