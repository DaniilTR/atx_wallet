part of '../home_page.dart';

class _SwapSheet extends StatefulWidget {
  const _SwapSheet();

  @override
  State<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends State<_SwapSheet> {
  final _amountCtrl = TextEditingController();
  TokenMetadata? _fromToken;
  TokenMetadata? _toToken;
  double _preview = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tokens = WalletScope.read(context).supportedTokens;
    _fromToken ??= tokens.first;
    _toToken ??= tokens.length > 1 ? tokens[1] : tokens.first;
    _recalculate();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double? _parseInput() {
    final raw = _amountCtrl.text.replaceAll(',', '.');
    if (raw.trim().isEmpty) return null;
    return double.tryParse(raw);
  }

  void _recalculate() {
    final amount = _parseInput();
    if (!mounted) return;
    final from = _fromToken;
    final to = _toToken;
    if (amount == null || amount <= 0 || from == null || to == null) {
      setState(() => _preview = 0);
      return;
    }
    final wallet = WalletScope.read(context);
    final next = wallet.convertAmount(from: from, to: to, amount: amount);
    setState(() => _preview = next);
  }

  void _swapDirection() {
    setState(() {
      final temp = _fromToken;
      _fromToken = _toToken;
      _toToken = temp;
    });
    _recalculate();
  }

  void _showPreviewSnack() {
    final from = _fromToken;
    final to = _toToken;
    if (from == null || to == null) return;
    final amount = _parseInput();
    if (amount == null || amount <= 0) return;
    final receive = _preview;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Обмен: ${_formatNumber(amount, precision: 4)} ${from.symbol} → ${_formatNumber(receive, precision: 4)} ${to.symbol}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = WalletScope.read(context);
    final tokens = wallet.supportedTokens;
    final fromBalance = _fromToken == null
        ? null
        : wallet.balanceForSymbol(_fromToken!.symbol)?.amount;
    final available = fromBalance ?? 0;

    return _SheetContainer(
      title: 'Обменять активы',
      subtitle: 'Выберите пары для свопа',
      child: Column(
        children: [
          _SwapCard(
            label: 'Отдаю',
            token: _fromToken?.symbol ?? '—',
            amount: _formatNumber(_parseInput() ?? 0, precision: 4),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TokenMetadata>(
            value: _fromToken,
            decoration: InputDecoration(
              labelText: 'Токен списания',
              filled: true,
              fillColor: const Color(0xFF1A223E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            dropdownColor: const Color(0xFF1A223E),
            items: tokens
                .map(
                  (token) => DropdownMenuItem<TokenMetadata>(
                    value: token,
                    child: Text('${token.name} (${token.symbol})'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _fromToken = value);
              _recalculate();
            },
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Сумма',
            hint: '0.00',
            prefixIcon: Icons.swap_horiz,
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _recalculate(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Доступно: ${_formatNumber(available, precision: 6)} ${_fromToken?.symbol ?? ''}',
              style: GoogleFonts.inter(color: const Color(0xFF8B96B8)),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _swapDirection,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2540),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x336FE1F5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.swap_vert_rounded, color: Color(0xFF6FE1F5)),
                  SizedBox(width: 8),
                  Text('Поменять местами'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TokenMetadata>(
            value: _toToken,
            decoration: InputDecoration(
              labelText: 'Токен получения',
              filled: true,
              fillColor: const Color(0xFF1A223E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            dropdownColor: const Color(0xFF1A223E),
            items: tokens
                .map(
                  (token) => DropdownMenuItem<TokenMetadata>(
                    value: token,
                    child: Text('${token.name} (${token.symbol})'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _toToken = value);
              _recalculate();
            },
          ),
          const SizedBox(height: 18),
          _SwapCard(
            label: 'Получаю',
            token: _toToken?.symbol ?? '—',
            amount: _formatNumber(_preview, precision: 4),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            label: 'Предпросмотр обмена',
            onPressed: _preview <= 0 ? null : () => _showPreviewSnack(),
          ),
        ],
      ),
    );
  }
}
