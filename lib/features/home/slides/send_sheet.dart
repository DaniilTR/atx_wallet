part of '../home_page.dart';

class _SendSheet extends StatefulWidget {
  const _SendSheet({required this.address, this.initialRecipient});

  final String? address;
  final String? initialRecipient;

  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  final _formKey = GlobalKey<FormState>();
  final _toCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  TokenMetadata? _selectedToken;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecipient;
    if (initial != null && initial.isNotEmpty) {
      _toCtrl.text = initial;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedToken ??= WalletScope.read(context).supportedTokens.first;
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  AssetBalance? get _selectedBalance {
    final symbol = _selectedToken?.symbol;
    if (symbol == null) return null;
    return WalletScope.read(context).balanceForSymbol(symbol);
  }

  double? _tryParseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String? _validateAddress(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Введите адрес получателя';
    final pattern = RegExp(r'^0x[a-fA-F0-9]{40}$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Некорректный адрес';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    final parsed = _tryParseAmount(value);
    if (parsed == null || parsed <= 0) {
      return 'Введите сумму больше 0';
    }
    final balance = _selectedBalance?.amount;
    if (balance != null && parsed > balance) {
      return 'Недостаточно средств (доступно ${_formatNumber(balance, precision: 6)})';
    }
    return null;
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;
    final token = _selectedToken;
    if (token == null) return;
    final amount = _tryParseAmount(_amountCtrl.text)!;
    setState(() => _sending = true);
    FocusScope.of(context).unfocus();
    final wallet = WalletScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final txHash = await wallet.sendAsset(
        token: token,
        recipient: _toCtrl.text.trim(),
        amount: amount,
      );
      if (!mounted) return;
      navigator.maybePop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Транзакция отправлена: $txHash',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF14191E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = WalletScope.read(context);
    final tokens = wallet.supportedTokens;
    final token = _selectedToken ?? tokens.first;
    final balanceLabel =
        '${_formatNumber(_selectedBalance?.amount ?? 0, precision: 6)} ${token.symbol}';
    final fromAddress = widget.address;

    return _SheetContainer(
      title: 'Отправить средства',
      subtitle: 'Введите адрес и сумму перевода',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fromAddress != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'С вашего адреса: ${_shortAddress(fromAddress)}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8B96B8),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<TokenMetadata>(
              initialValue: token,
              decoration: InputDecoration(
                labelText: 'Токен',
                labelStyle: GoogleFonts.inter(color: const Color(0xFFB5BEDF)),
                filled: true,
                fillColor: const Color(0xFF14191E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              dropdownColor: const Color(0xFF14191E),
              items: tokens
                  .map(
                    (t) => DropdownMenuItem<TokenMetadata>(
                      value: t,
                      child: Text('${t.name} (${t.symbol})'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedToken = value);
                _formKey.currentState?.validate();
              },
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Адрес получателя',
              hint: '0x…',
              prefixIcon: Icons.account_balance_wallet_outlined,
              controller: _toCtrl,
              textInputAction: TextInputAction.next,
              validator: _validateAddress,
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: 'Сумма',
              hint: '0.00 ${token.symbol}',
              prefixIcon: Icons.attach_money,
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validateAmount,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 14),
            _InfoChip(text: 'Доступно: $balanceLabel'),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: _sending ? 'Отправляем…' : 'Отправить',
              onPressed: _sending ? null : () => _handleSend(),
            ),
          ],
        ),
      ),
    );
  }

  String _shortAddress(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
  }
}
