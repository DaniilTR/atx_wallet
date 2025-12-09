part of '../home_page.dart';

class _SwapSheet extends StatelessWidget {
  const _SwapSheet();

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Обменять активы',
      subtitle: 'Выберите пары для свопа',
      child: Column(
        children: [
          _SwapCard(label: 'Отдаю', token: 'ATX', amount: '0.0000'),
          const SizedBox(height: 12),
          const Icon(Icons.swap_vert_rounded, color: Color(0xFF6FE1F5)),
          const SizedBox(height: 12),
          _SwapCard(label: 'Получаю', token: 'USDT', amount: '0.00'),
          const SizedBox(height: 20),
          _PrimaryButton(
            label: 'Предпросмотр обмена',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
