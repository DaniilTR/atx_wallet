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

  bool _quoteLoading = false;
  String? _quoteError;
  BigInt? _quotedOutRaw;
  double _preview = 0;

  bool _approveLoading = false;
  bool _swapLoading = false;
  Timer? _quoteDebounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tokens = WalletScope.read(
      context,
    ).supportedTokens.where((t) => !t.isBitcoin).toList(growable: false);

    if (tokens.isEmpty) return;

    _fromToken ??= tokens.first;
    _toToken ??= tokens.length > 1 ? tokens[1] : tokens.first;

    // Если вдруг получилось выбрать одинаковые токены (например, после изменения
    // списка поддерживаемых токенов) — подбираем альтернативу автоматически.
    final from = _fromToken;
    final to = _toToken;
    if (from != null && to != null && _isSameToken(from, to)) {
      final alt = _pickAlternativeToken(tokens, avoid: from);
      if (alt != null) _toToken = alt;
    }
    _recalculate();
  }

  bool _isSameToken(TokenMetadata a, TokenMetadata b) {
    if (a.isNative && b.isNative) return true;
    if (a.isNative != b.isNative) return false;
    final ca = a.contractAddress?.toLowerCase();
    final cb = b.contractAddress?.toLowerCase();
    return ca != null && cb != null && ca == cb;
  }

  TokenMetadata? _pickAlternativeToken(
    List<TokenMetadata> tokens, {
    required TokenMetadata avoid,
  }) {
    for (final t in tokens) {
      if (!_isSameToken(t, avoid)) return t;
    }
    return null;
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    _amountCtrl.dispose();
    super.dispose();
  }

  double? _parseInput() {
    final raw = _amountCtrl.text.replaceAll(',', '.');
    if (raw.trim().isEmpty) return null;
    return double.tryParse(raw);
  }

  void _recalculate() {
    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _refreshQuote();
    });
  }

  Future<void> _refreshQuote() async {
    final amount = _parseInput();
    final from = _fromToken;
    final to = _toToken;
    if (!mounted) return;

    if (kEvmChainId != 1) {
      setState(() {
        _quoteLoading = false;
        _quoteError = 'Swap доступен только в Ethereum Mainnet (chainId=1)';
        _quotedOutRaw = null;
        _preview = 0;
      });
      return;
    }

    if (amount == null || amount <= 0 || from == null || to == null) {
      setState(() {
        _quoteLoading = false;
        _quoteError = null;
        _quotedOutRaw = null;
        _preview = 0;
      });
      return;
    }

    // Uniswap V2 не принимает путь из одинаковых адресов.
    if (_isSameToken(from, to)) {
      setState(() {
        _quoteLoading = false;
        _quoteError = 'Выберите разные токены для обмена';
        _quotedOutRaw = null;
        _preview = 0;
      });
      return;
    }

    if (from.isBitcoin || to.isBitcoin) {
      setState(() {
        _quoteLoading = false;
        _quoteError = 'Swap доступен только для EVM-активов';
        _quotedOutRaw = null;
        _preview = 0;
      });
      return;
    }

    final wallet = WalletScope.read(context);
    final profile = wallet.activeProfile;
    final addressHex = profile?.addressHex;
    final pk = wallet.privateKey;
    if (addressHex == null || pk == null) {
      setState(() {
        _quoteLoading = false;
        _quoteError = 'Кошелёк не готов (нет адреса/ключа)';
        _quotedOutRaw = null;
        _preview = 0;
      });
      return;
    }

    setState(() {
      _quoteLoading = true;
      _quoteError = null;
    });

    try {
      final router = UniswapV2RouterService(client: wallet.blockchain.client);
      await router.assertRouterReady();

      final amountInRaw = _toBaseUnits(amount, from.decimalsHint);
      final path = _buildPath(router: router, from: from, to: to);
      final amounts = await router.getAmountsOut(
        amountIn: amountInRaw,
        path: path,
      );
      final outRaw = amounts.isNotEmpty ? amounts.last : BigInt.zero;
      final outDecimals = to.isNative ? 18 : to.decimalsHint;
      final outAmount = _fromBaseUnits(outRaw, outDecimals);
      if (!mounted) return;
      setState(() {
        _quotedOutRaw = outRaw;
        _preview = outAmount;
        _quoteLoading = false;
        _quoteError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quoteLoading = false;
        _quoteError = e.toString();
        _quotedOutRaw = null;
        _preview = 0;
      });
    }
  }

  List<EthereumAddress> _buildPath({
    required UniswapV2RouterService router,
    required TokenMetadata from,
    required TokenMetadata to,
  }) {
    EthereumAddress addr(TokenMetadata t) {
      if (t.isNative) return router.wethAddress;
      return EthereumAddress.fromHex(t.contractAddress!.toLowerCase());
    }

    return <EthereumAddress>[addr(from), addr(to)];
  }

  Future<bool> _ensureAllowance({
    required TokenMetadata from,
    required BigInt amountInRaw,
    required EthereumAddress owner,
  }) async {
    if (from.isNative) return true;
    final wallet = WalletScope.read(context);
    final pk = wallet.privateKey;
    if (pk == null) return false;

    final router = UniswapV2RouterService(client: wallet.blockchain.client);
    final erc20 = Erc20Service(client: wallet.blockchain.client);
    final tokenAddr = EthereumAddress.fromHex(
      from.contractAddress!.toLowerCase(),
    );

    final current = await erc20.allowance(
      token: tokenAddr,
      owner: owner,
      spender: router.routerAddress,
    );
    if (current >= amountInRaw) return true;

    setState(() => _approveLoading = true);
    try {
      await router.assertRouterReady();
      await erc20.safeApprove(
        token: tokenAddr,
        privateKeyHex: pk,
        spender: router.routerAddress,
        amount: amountInRaw,
        owner: owner,
      );

      final pollDeadline = DateTime.now().add(const Duration(seconds: 45));
      while (DateTime.now().isBefore(pollDeadline)) {
        final next = await erc20.allowance(
          token: tokenAddr,
          owner: owner,
          spender: router.routerAddress,
        );
        if (next >= amountInRaw) return true;
        await Future<void>.delayed(const Duration(seconds: 3));
      }

      return false;
    } finally {
      if (mounted) setState(() => _approveLoading = false);
    }
  }

  Future<void> _executeSwap() async {
    final amount = _parseInput();
    final from = _fromToken;
    final to = _toToken;
    if (amount == null || amount <= 0 || from == null || to == null) return;

    if (_isSameToken(from, to)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите разные токены для обмена')),
      );
      return;
    }

    if (kEvmChainId != 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swap доступен только в Ethereum Mainnet (chainId=1)'),
        ),
      );
      return;
    }

    final wallet = WalletScope.read(context);
    final fromBalance = wallet.balanceForSymbol(from.symbol)?.amount ?? 0;
    if (amount > fromBalance) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно средств для обмена')),
      );
      return;
    }
    final profile = wallet.activeProfile;
    final addressHex = profile?.addressHex;
    final pk = wallet.privateKey;
    if (addressHex == null || pk == null) return;

    final owner = EthereumAddress.fromHex(addressHex.toLowerCase());
    final router = UniswapV2RouterService(client: wallet.blockchain.client);

    final amountInRaw = _toBaseUnits(amount, from.decimalsHint);
    final path = _buildPath(router: router, from: from, to: to);
    final outRaw = _quotedOutRaw;
    if (outRaw == null || outRaw <= BigInt.zero) return;

    const slippageBps = 100; // 1.00%
    final amountOutMin =
      outRaw * BigInt.from(10000 - slippageBps) ~/ BigInt.from(10000);
    final deadline = BigInt.from(
      DateTime.now().add(const Duration(minutes: 15)).millisecondsSinceEpoch ~/
          1000,
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтвердить обмен'),
        content: Text(
          'Сеть: chainId=$kEvmChainId\n'
          'Router: ${router.routerAddress.hexEip55}\n\n'
          'Отдаю: ${_formatNumber(amount, precision: 6)} ${from.symbol}\n'
          'Получаю (ожид.): ${_formatNumber(_preview, precision: 6)} ${to.symbol}\n'
          'Мин. получу: ${_formatNumber(_fromBaseUnits(amountOutMin, to.isNative ? 18 : to.decimalsHint), precision: 6)} ${to.symbol}\n'
          'Slippage: 1%\n'
          'Deadline: 15 мин',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _swapLoading = true);
    try {
      await router.assertRouterReady();

      final allowanceOk = await _ensureAllowance(
        from: from,
        amountInRaw: amountInRaw,
        owner: owner,
      );
      if (!allowanceOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось подтвердить allowance для swap'),
          ),
        );
        return;
      }

      String tx;
      if (from.isNative && !to.isNative) {
        tx = await router.swapExactETHForTokens(
          privateKeyHex: pk,
          amountInWei: amountInRaw,
          amountOutMin: amountOutMin,
          path: path,
          recipient: owner,
          deadline: deadline,
        );
      } else if (!from.isNative && to.isNative) {
        tx = await router.swapExactTokensForETH(
          privateKeyHex: pk,
          amountIn: amountInRaw,
          amountOutMin: amountOutMin,
          path: path,
          recipient: owner,
          deadline: deadline,
        );
      } else {
        tx = await router.swapExactTokensForTokens(
          privateKeyHex: pk,
          amountIn: amountInRaw,
          amountOutMin: amountOutMin,
          path: path,
          recipient: owner,
          deadline: deadline,
        );
      }

      if (!mounted) return;

      if (kColdWalletMode) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Подписано (cold): $tx')));
        return;
      }

      final txHash = tx;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Обмен отправлен. Tx: ${txHash.substring(0, 10)}...'),
        ),
      );
      unawaited(
        _pollSwapReceiptAndReport(
          txHash: txHash,
          client: wallet.blockchain.client,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Swap error: $e')));
    } finally {
      if (mounted) setState(() => _swapLoading = false);
    }
  }

  Future<void> _pollSwapReceiptAndReport({
    required String txHash,
    required Web3Client client,
  }) async {
    final started = DateTime.now();
    const timeout = Duration(minutes: 3);
    var delay = const Duration(seconds: 3);

    while (DateTime.now().difference(started) < timeout) {
      try {
        final receipt = await client.getTransactionReceipt(txHash);
        if (receipt != null) {
          final status = receipt.status;
          final ok = status == null
              ? true
              : status == true ||
                    status == 1 ||
                    status == BigInt.one ||
                    status.toString() == '1';
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok
                    ? 'Swap успешно подтвержден. Tx: ${txHash.substring(0, 10)}...'
                    : 'Swap отклонён сетью/контрактом. Tx: ${txHash.substring(0, 10)}...',
              ),
            ),
          );
          return;
        }
      } catch (_) {
        // ignore and retry
      }

      await Future<void>.delayed(delay);
      if (delay < const Duration(seconds: 12)) {
        delay *= 2;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Нет подтверждения за 3 минуты (проверьте tx в обозревателе). Tx: ${txHash.substring(0, 10)}...',
        ),
      ),
    );
  }

  double _fromBaseUnits(BigInt amount, int decimals) {
    if (amount == BigInt.zero) return 0;
    final divisor = math.pow(10, decimals).toDouble();
    return amount.toDouble() / divisor;
  }

  BigInt _toBaseUnits(double amount, int decimals) {
    final fixed = amount.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final whole = BigInt.parse(parts.first);
    final fraction = parts.length > 1 ? parts[1] : '';
    final padded = fraction.padRight(decimals, '0');
    final fractionValue = padded.isEmpty ? BigInt.zero : BigInt.parse(padded);
    final base = BigInt.from(10).pow(decimals);
    return whole * base + fractionValue;
  }

  void _swapDirection() {
    final wallet = WalletScope.read(context);
    final tokens = wallet.supportedTokens.where((t) => !t.isBitcoin).toList();
    setState(() {
      final temp = _fromToken;
      _fromToken = _toToken;
      _toToken = temp;

      final from = _fromToken;
      final to = _toToken;
      if (from != null && to != null && _isSameToken(from, to)) {
        final alt = _pickAlternativeToken(tokens, avoid: from);
        if (alt != null) _toToken = alt;
      }
    });
    _recalculate();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = WalletScope.read(context);
    final tokens = wallet.supportedTokens.where((t) => !t.isBitcoin).toList();
    final fromBalance = _fromToken == null
        ? null
        : wallet.balanceForSymbol(_fromToken!.symbol)?.amount;
    final available = fromBalance ?? 0;

    return _SheetContainer(
      title: 'Обменять активы',
      subtitle: 'Выберите пары для свопа',
      child: Column(
        children: [
          _LabeledField(
            label: 'Сумма',
            hint: '0.00',
            prefixIcon: Icons.swap_horiz,
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _recalculate(),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<TokenMetadata>(
            value: _fromToken,
            decoration: InputDecoration(
              labelText: 'Токен списания',
              filled: true,
              fillColor: const Color(0xFF14191E),
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
              setState(() {
                _fromToken = value;
                final to = _toToken;
                if (to != null && _isSameToken(value, to)) {
                  final alt = _pickAlternativeToken(tokens, avoid: value);
                  if (alt != null) _toToken = alt;
                }
              });
              _recalculate();
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: _quoteLoading
                ? Text(
                    'Получаем котировку...',
                    style: GoogleFonts.inter(color: const Color(0xFF8B96B8)),
                  )
                : _quoteError != null
                ? Text(
                    'Котировка недоступна: ${_quoteError!}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFF8F8F),
                      fontSize: 12,
                    ),
                  )
                : const SizedBox.shrink(),
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
                color: const Color(0xFF14191E),
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
              fillColor: const Color(0xFF14191E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            dropdownColor: const Color(0xFF14191E),
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
              setState(() {
                _toToken = value;
                final from = _fromToken;
                if (from != null && _isSameToken(from, value)) {
                  final alt = _pickAlternativeToken(tokens, avoid: value);
                  if (alt != null) _fromToken = alt;
                }
              });
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
            label: _swapLoading
                ? 'Обмен выполняется...'
                : _approveLoading
                ? 'Подтверждаем allowance...'
                : 'Обменять (Uniswap V2)',
            onPressed:
                (_preview <= 0 ||
                    _quoteLoading ||
                    _approveLoading ||
                    _swapLoading)
                ? null
                : () => _executeSwap(),
          ),
        ],
      ),
    );
  }
}
