part of '../home_page.dart';

class _HistorySheet extends StatelessWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context) {
    final history = [
      ('Перевод', '-45.00 ATX', 'Сегодня, 12:44'),
      ('Получение', '+120.00 USDT', 'Вчера, 18:10'),
      ('Обмен', '-0.05 BTC', '02.12, 09:30'),
      ('Купить', '+300.00 ATX', '01.12, 17:05'),
    ];
    return _SheetContainer(
      title: 'История операций',
      subtitle: 'Последние транзакции кошелька',
      child: SizedBox(
        height: 280,
        child: ListView.separated(
          itemBuilder: (context, index) {
            final item = history[index];
            final isNegative = item.$2.startsWith('-');
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x222E9AFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isNegative
                      ? Icons.arrow_outward_rounded
                      : Icons.arrow_downward_rounded,
                  color: Colors.white,
                ),
              ),
              title: Text(
                item.$1,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                item.$3,
                style: GoogleFonts.inter(
                  color: const Color(0xFF7C86B2),
                  fontSize: 12,
                ),
              ),
              trailing: Text(
                item.$2,
                style: GoogleFonts.inter(
                  color: isNegative
                      ? const Color(0xFFFF8484)
                      : const Color(0xFF5EF2C1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(color: Color(0x221C2743)),
          itemCount: history.length,
        ),
      ),
    );
  }
}
