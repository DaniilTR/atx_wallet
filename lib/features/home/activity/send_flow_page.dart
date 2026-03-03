part of '../home_page.dart';

class _SendFlowPage extends StatefulWidget {
  const _SendFlowPage({this.initialRecipient});

  final String? initialRecipient;

  @override
  State<_SendFlowPage> createState() => _SendFlowPageState();
}

class _SendFlowPageState extends State<_SendFlowPage> {
  final _formKey = GlobalKey<FormState>();
  final _toCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  TokenMetadata? _selectedToken;
  int _step = 0;

  bool _loadingPreflight = false;
  bool _sending = false;
  SendPreflightResult? _preflight;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecipient;
    if (initial != null && initial.trim().isNotEmpty) {
      _toCtrl.text = initial.trim();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wallet = WalletScope.read(context);
    final tokens = wallet.supportedTokens.toList(growable: false);
    if (tokens.isEmpty) return;
    _selectedToken ??= tokens.first;
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
    final token = _selectedToken;
    if (token == null) return 'Некорректный адрес';

    if (token.isBitcoin) {
      final pattern = RegExp(r'^1[a-km-zA-HJ-NP-Z1-9]{25,34}$');
      if (!pattern.hasMatch(trimmed)) {
        return 'Некорректный BTC адрес (только legacy 1…)';
      }
      return null;
    }

    final pattern = RegExp(r'^0x[a-fA-F0-9]{40}$');
    if (!pattern.hasMatch(trimmed)) return 'Некорректный адрес';
    return null;
  }

  String? _validateAmount(String? value) {
    final parsed = _tryParseAmount(value);
    if (parsed == null || parsed <= 0) {
      return 'Введите сумму больше 0';
    }
    if (_selectedBalance == null) {
      return 'Баланс ещё не загружен. Обновите баланс и попробуйте снова.';
    }
    final balance = _selectedBalance?.amount;
    if (balance != null && parsed > balance) {
      return 'Недостаточно средств (доступно ${_formatNumber(balance, precision: 6)})';
    }
    return null;
  }

  Future<void> _goToConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    final token = _selectedToken;
    if (token == null) return;

    final amount = _tryParseAmount(_amountCtrl.text)!;
    final recipient = _toCtrl.text.trim();

    setState(() {
      _loadingPreflight = true;
      _preflight = null;
    });

    FocusScope.of(context).unfocus();
    final wallet = WalletScope.read(context);

    try {
      final preflight = await wallet.preflightSend(
        token: token,
        recipient: recipient,
        amount: amount,
      );
      if (!mounted) return;
      setState(() {
        _preflight = preflight;
        _step = 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), style: GoogleFonts.inter())),
      );
    } finally {
      if (mounted) setState(() => _loadingPreflight = false);
    }
  }

  Future<void> _confirmSend() async {
    final preflight = _preflight;
    final token = _selectedToken;
    if (preflight == null || token == null) return;

    final wallet = WalletScope.read(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _sending = true);
    try {
      final tx = await wallet.sendAsset(
        token: token,
        recipient: preflight.recipient,
        amount: preflight.amount,
      );
      if (!mounted) return;
      final label = kColdWalletMode
          ? 'Транзакция подписана (raw, не отправлена): ${_shortTx(tx)}'
          : 'Транзакция отправлена: ${_shortTx(tx)}';
      messenger.showSnackBar(
        SnackBar(content: Text(label, style: GoogleFonts.inter())),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString(), style: GoogleFonts.inter())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _handleBack() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step = 0);
  }

  Future<void> _showFeeInfoSheet() async {
    final preflight = _preflight;
    if (preflight == null) return;

    final isRed = preflight.feeStatus == FeeStatus.insufficientFee;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: viewInsets.bottom + 20,
              top: 12,
            ),
            child: _SheetContainer(
              title: isRed ? 'Недостаточно средств' : 'Комиссия сети (gas)',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  if (isRed) ...[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x221EF4A6),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF5C5C),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x331B2430),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x22FF5C5C)),
                      ),
                      child: Text(
                        preflight.feeWarningText ??
                            'У вас на счету недостаточно ETH для оплаты комиссии сети.',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PrimaryButton(
                      label: 'Понятно',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    const SizedBox(height: 10),
                    _PrimaryButton(
                      label: 'Купить ETH',
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Покупка ETH пока не подключена',
                              style: GoogleFonts.inter(),
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x331B2430),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x113D7CFF)),
                      ),
                      child: Text(
                        'Комиссия сети (gas) — это плата майнерам/валидаторам за выполнение транзакции в сети Ethereum.\n\n'
                        'Комиссия оплачивается в ETH и зависит от загруженности сети и сложности операции.',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PrimaryButton(
                      label: 'Понятно',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = WalletScope.read(context);
    final tokens = wallet.supportedTokens.toList(growable: false);
    final token = _selectedToken ?? (tokens.isNotEmpty ? tokens.first : null);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1317),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _step == 0 ? 'Отправить' : 'Проверить',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (token == null)
            const SizedBox.shrink()
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _step == 0
                  ? _buildStepForm(context, token, tokens)
                  : _buildStepConfirm(context, token),
            ),
          if (_loadingPreflight || _sending)
            Positioned.fill(
              child: Container(
                color: const Color(0x88000000),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepForm(
    BuildContext context,
    TokenMetadata token,
    List<TokenMetadata> tokens,
  ) {
    final balance = _selectedBalance;
    final amount = balance?.amount ?? 0;
    final amountLabel =
        '${_formatNumber(amount, precision: 6)} ${token.symbol}';

    final cs = Theme.of(context).colorScheme;
    final borderTint = Colors.white.withOpacity(0.22);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (_tokenColors[token.symbol] ?? cs.primary).withOpacity(
                    0.22,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    token.symbol,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                token.symbol,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 26),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Место назначения',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB5BEDF),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _toCtrl,
                validator: _validateAddress,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: token.isBitcoin
                      ? '1…'
                      : 'Введите или вставьте адрес',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF6A7398)),
                  filled: true,
                  fillColor: const Color(0xFF14191E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderTint, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderTint, width: 1),
                  ),
                  suffixIcon: Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Сумма',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB5BEDF),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                validator: _validateAmount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF6A7398)),
                  filled: true,
                  fillColor: const Color(0xFF14191E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderTint, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderTint, width: 1),
                  ),
                  suffixIcon: DropdownButtonHideUnderline(
                    child: DropdownButton<TokenMetadata>(
                      value: _selectedToken,
                      dropdownColor: const Color(0xFF14191E),
                      iconEnabledColor: Colors.white,
                      items: tokens
                          .map(
                            (t) => DropdownMenuItem<TokenMetadata>(
                              value: t,
                              child: Text(
                                t.symbol,
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedToken = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      amountLabel,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB5BEDF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final b = _selectedBalance?.amount;
                      if (b == null) return;
                      _amountCtrl.text = b.toString();
                    },
                    child: Text(
                      'Максимум',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7A5AF8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loadingPreflight ? null : _goToConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8B8B8),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF8B8B8B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Продолжить',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepConfirm(BuildContext context, TokenMetadata token) {
    final wallet = WalletScope.read(context);
    final fromName = wallet.activeProfile?.name ?? 'Кошелёк';
    final fromAddr = token.isBitcoin
        ? (wallet.bitcoinAddress ?? '—')
        : (wallet.activeProfile?.addressHex ?? '—');

    final preflight = _preflight;
    if (preflight == null) {
      return const SizedBox.shrink();
    }

    final feeColor = preflight.feeStatus == FeeStatus.insufficientFee
        ? const Color(0xFFFF5C5C)
        : Colors.white;

    final feeLabel = preflight.feeLabel;
    final speedLabel = preflight.speedLabel;

    final amountLabel =
        '${_formatNumber(preflight.amount, precision: 6)} ${token.symbol}';
    final receiveLabel =
        '${_formatNumber(preflight.amount, precision: 6)} ${token.symbol}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (_tokenColors[token.symbol] ?? const Color(0xFF7A5AF8))
                    .withOpacity(0.22),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                token.symbol,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              amountLabel,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              preflight.amountUsdLabel ?? '—',
              style: GoogleFonts.inter(
                color: const Color(0xFFB5BEDF),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              borderRadius: 18,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Из',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB5BEDF),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fromName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _shortAddress(fromAddr),
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB5BEDF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Место назначения',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB5BEDF),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Получатель',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _shortAddress(preflight.recipient),
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB5BEDF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 18,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Сеть',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB5BEDF),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFFB5BEDF),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      preflight.networkLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              borderRadius: 18,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    InkWell(
                      onTap: token.isBitcoin ? null : _showFeeInfoSheet,
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Комиссия сети',
                                  style: GoogleFonts.inter(
                                    color: feeColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (preflight.feeStatus ==
                                    FeeStatus.insufficientFee)
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                    color: Color(0xFFFF5C5C),
                                  )
                                else
                                  const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Color(0xFFB5BEDF),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            feeLabel,
                            style: GoogleFonts.inter(
                              color: feeColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Скорость',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFB5BEDF),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          speedLabel,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Получатель получит',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFB5BEDF),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          receiveLabel,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _handleBack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2F36),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Отмена',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _sending
                          ? null
                          : (preflight.canSend
                                ? _confirmSend
                                : (preflight.feeStatus ==
                                          FeeStatus.insufficientFee
                                      ? _showFeeInfoSheet
                                      : null)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: preflight.canSend
                            ? const Color(0xFF7A5AF8)
                            : const Color(0xFF3A3A3A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        preflight.canSend
                            ? 'Подтвердить'
                            : 'Просмотр оповещения',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
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

  String _shortTx(String value) {
    final v = value.trim();
    if (v.length <= 18) return v;
    return '${v.substring(0, 10)}...${v.substring(v.length - 6)}';
  }
}
