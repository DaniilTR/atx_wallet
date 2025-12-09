part of '../home_page.dart';

class _SendSheet extends StatelessWidget {
  const _SendSheet({required this.address});

  final String? address;

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Отправить средства',
      subtitle: 'Введите адрес и сумму перевода',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabeledField(
            label: 'Адрес получателя',
            hint: '0x…',
            prefixIcon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 14),
          _LabeledField(
            label: 'Сумма',
            hint: '0.00 ATX',
            prefixIcon: Icons.attach_money,
          ),
          const SizedBox(height: 14),
          _InfoChip(text: 'Баланс: ${address == null ? '—' : 'активен'}'),
          const SizedBox(height: 20),
          _PrimaryButton(
            label: 'Отправить',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
