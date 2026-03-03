import 'dart:convert';

import 'package:dartsv/dartsv.dart' as dartsv;
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;

/// Bitcoin-сервис для приложения:
///
/// - деривация BTC-адреса (mainnet) из BIP-39 сид-фразы
/// - чтение баланса через публичный API blockstream.info
/// - сборка/подпись P2PKH-транзакций (legacy) и отправка в сеть
///
/// Ограничения текущей реализации:
/// - только **mainnet**
/// - только **legacy P2PKH** адреса (Base58, начинаются с `1`)
/// - UTXO берём по адресу и тратим только подтверждённые UTXO
class BitcoinService {
  BitcoinService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// BIP44-путь для Bitcoin (основная сеть).
  ///
  /// Здесь используется legacy-адрес (P2PKH, формат Base58 начиная с '1...'),
  /// потому что так проще для демонстрации и шире поддержка эксплорерами.
  ///
  /// Если позже понадобится SegWit (bc1...) — derivation и формат адреса нужно
  /// будет поменять.
  static const String kDerivationPath = "m/44'/0'/0'/0/0";

  static final BigInt _dustSats = BigInt.from(546);
  static const int _defaultFeeTargetBlocks = 3;

  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
    'User-Agent': 'atx_wallet/1.0',
  };

  static const Map<String, String> _textHeaders = {
    'Accept': 'text/plain',
    'Content-Type': 'text/plain',
    'User-Agent': 'atx_wallet/1.0',
  };

  /// Деривирует BTC-адрес основной сети из сид-фразы (мнемоники).
  ///
  /// Нормализация:
  /// - обрезка пробелов по краям (trim())
  /// - приведение к нижнему регистру (toLowerCase())
  /// - схлопывание пробелов
  ///
  /// Это сделано, чтобы одна и та же сид-фраза давала один и тот же адрес.
  String deriveMainnetAddressFromMnemonic(String mnemonic) {
    final normalized = mnemonic.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    final seedHex = dartsv.Mnemonic().toSeedHex(normalized);
    final root = dartsv.HDPrivateKey.fromSeed(seedHex, dartsv.NetworkType.MAIN);
    final child = root.deriveChildKey(kDerivationPath);
    final address = dartsv.Address.fromPublicKey(
      child.publicKey,
      dartsv.NetworkType.MAIN,
    );
    return address.toBase58();
  }

  /// Деривирует приватный ключ BTC (mainnet) в формате WIF из сид-фразы.
  ///
  /// Используется для подписи транзакций.
  String deriveMainnetPrivateKeyWifFromMnemonic(String mnemonic) {
    final normalized = mnemonic.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    final seedHex = dartsv.Mnemonic().toSeedHex(normalized);
    final root = dartsv.HDPrivateKey.fromSeed(seedHex, dartsv.NetworkType.MAIN);
    final child = root.deriveChildKey(kDerivationPath);

    // keyBuffer = 0x00 || ser256(k)
    final keyBytes = child.keyBuffer.sublist(1);
    final priv = dartsv.SVPrivateKey.fromHex(
      HEX.encode(keyBytes),
      dartsv.NetworkType.MAIN,
    );
    return priv.toWIF();
  }

  /// Возвращает баланс в сатоши.
  ///
  /// Используем blockstream.info API:
  /// `GET /api/address/<address>`
  ///
  /// Баланс считается как funded_txo_sum - spent_txo_sum отдельно для
  /// chain_stats (подтверждённые) и mempool_stats (неподтверждённые), затем складываем.
  Future<BigInt> fetchBalanceSats(String address) async {
    final uri = Uri.https('blockstream.info', '/api/address/$address');
    final res = await _httpClient.get(uri, headers: _jsonHeaders);

    if (res.statusCode != 200) {
      throw StateError('Ошибка BTC-эксплорера (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Неожиданный формат ответа BTC-эксплорера');
    }

    BigInt readBigInt(dynamic value) {
      if (value is int) return BigInt.from(value);
      if (value is num) return BigInt.from(value.toInt());
      return BigInt.tryParse('$value') ?? BigInt.zero;
    }

    final chain = decoded['chain_stats'] as Map<String, dynamic>?;
    final mempool = decoded['mempool_stats'] as Map<String, dynamic>?;

    BigInt balancePart(Map<String, dynamic>? stats) {
      if (stats == null) return BigInt.zero;
      final funded = readBigInt(stats['funded_txo_sum']);
      final spent = readBigInt(stats['spent_txo_sum']);
      return funded - spent;
    }

    final confirmed = balancePart(chain);
    final unconfirmed = balancePart(mempool);
    return confirmed + unconfirmed;
  }

  /// UTXO записи с blockstream: `GET /api/address/<address>/utxo`.
  Future<List<_BtcUtxo>> fetchConfirmedUtxos(String address) async {
    final uri = Uri.https('blockstream.info', '/api/address/$address/utxo');
    final res = await _httpClient.get(uri, headers: _jsonHeaders);
    if (res.statusCode != 200) {
      throw StateError('Ошибка BTC-эксплорера (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw StateError('Неожиданный формат ответа BTC-эксплорера');
    }

    final utxos = <_BtcUtxo>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final txid = item['txid']?.toString() ?? '';
      final vout = item['vout'];
      final value = item['value'];
      final status = item['status'];
      final confirmed = status is Map<String, dynamic>
          ? (status['confirmed'] == true)
          : false;
      if (!confirmed) continue;
      if (txid.isEmpty) continue;
      if (vout is! int) continue;
      if (value is! int) continue;
      utxos.add(
        _BtcUtxo(txid: txid, vout: vout, valueSats: BigInt.from(value)),
      );
    }

    // Чтобы уменьшить комиссию, выгоднее тратить меньше входов.
    utxos.sort((a, b) => b.valueSats.compareTo(a.valueSats));
    return utxos;
  }

  /// Оценка комиссии: `GET /api/fee-estimates`.
  ///
  /// Возвращает sats/vbyte (целое), берём target по умолчанию 3 блока.
  Future<int> fetchFeeRateSatsPerVbyte({
    int targetBlocks = _defaultFeeTargetBlocks,
  }) async {
    final uri = Uri.https('blockstream.info', '/api/fee-estimates');
    final res = await _httpClient.get(uri, headers: _jsonHeaders);
    if (res.statusCode != 200) {
      // fallback: консервативно
      return 5;
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) return 5;
    final raw = decoded['$targetBlocks'];
    if (raw is num) {
      final v = raw.ceil();
      return v <= 0 ? 5 : v;
    }
    return 5;
  }

  /// Создаёт и подписывает raw BTC-транзакцию (P2PKH) и возвращает hex.
  ///
  /// Входы берём из подтверждённых UTXO адреса, change возвращаем на этот же адрес.
  Future<String> buildSignedP2pkhTransactionHex({
    required String fromWif,
    required String fromAddress,
    required String toAddress,
    required BigInt amountSats,
    required int feeRateSatsPerVbyte,
  }) async {
    if (amountSats <= BigInt.zero) {
      throw ArgumentError.value(amountSats, 'amountSats', 'should be > 0');
    }
    if (amountSats < _dustSats) {
      throw Exception('Сумма слишком мала для сети BTC (dust).');
    }
    if (feeRateSatsPerVbyte <= 0) {
      throw ArgumentError.value(
        feeRateSatsPerVbyte,
        'feeRateSatsPerVbyte',
        'should be > 0',
      );
    }

    // Валидируем адреса (в dartsv — только Base58).
    late final dartsv.Address from;
    late final dartsv.Address to;
    try {
      from = dartsv.Address(fromAddress);
      to = dartsv.Address(toAddress);
    } catch (_) {
      throw Exception('Некорректный BTC адрес. Поддерживаются Base58 адреса.');
    }

    // Текущая реализация кошелька — только P2PKH (legacy) адреса.
    if (!from.toBase58().startsWith('1') || !to.toBase58().startsWith('1')) {
      throw Exception(
        'Поддерживаются только BTC legacy адреса формата 1… (P2PKH).',
      );
    }

    final signingKey = dartsv.SVPrivateKey.fromWIF(fromWif);
    final pubKey = signingKey.publicKey;
    final signer = dartsv.TransactionSigner(
      dartsv.SighashType.SIGHASH_ALL.value,
      signingKey,
    );

    final utxos = await fetchConfirmedUtxos(from.toBase58());
    if (utxos.isEmpty) {
      throw Exception('Нет подтверждённых UTXO для отправки BTC.');
    }

    // P2PKH locking script для наших UTXO (в этой версии кошелька адрес только P2PKH).
    final lockingScript = dartsv.P2PKHLockBuilder.fromAddress(
      from,
    ).getScriptPubkey();

    final selected = <_BtcUtxo>[];
    BigInt selectedTotal = BigInt.zero;

    // Подбираем UTXO так, чтобы хватило на amount + fee.
    while (selected.length < utxos.length) {
      final next = utxos[selected.length];
      selected.add(next);
      selectedTotal += next.valueSats;

      final inputs = selected.length;

      // Сначала предполагаем, что будет change-output.
      final feeWithChange = _estimateP2pkhFeeSats(
        inputs: inputs,
        outputs: 2,
        feeRateSatsPerVbyte: feeRateSatsPerVbyte,
      );
      final requiredWithChange = amountSats + feeWithChange;
      if (selectedTotal < requiredWithChange) {
        continue;
      }

      final change = selectedTotal - requiredWithChange;
      if (change >= _dustSats) {
        // ОК: делаем tx с change.
        final builder = dartsv.TransactionBuilder();
        for (final u in selected) {
          final outpoint = dartsv.TransactionOutpoint(
            u.txid,
            u.vout,
            u.valueSats,
            lockingScript,
          );
          builder.spendFromOutpointWithSigner(
            signer,
            outpoint,
            dartsv.TransactionInput.MAX_SEQ_NUMBER,
            dartsv.P2PKHUnlockBuilder(pubKey),
          );
        }
        builder
          ..spendToPKH(to, amountSats)
          ..withFee(feeWithChange)
          ..sendChangeToPKH(from);

        final tx = builder.build(true);
        return tx.serialize();
      }

      // Change меньше dust — попробуем вариант без change (всё сверх amount уйдёт в fee).
      final feeNoChangeMin = _estimateP2pkhFeeSats(
        inputs: inputs,
        outputs: 1,
        feeRateSatsPerVbyte: feeRateSatsPerVbyte,
      );
      final requiredNoChange = amountSats + feeNoChangeMin;
      if (selectedTotal < requiredNoChange) {
        continue;
      }

      final feeNoChange = selectedTotal - amountSats;
      if (feeNoChange < feeNoChangeMin) {
        continue;
      }

      final builder = dartsv.TransactionBuilder()
        ..withFee(feeNoChange)
        ..spendToPKH(to, amountSats);

      for (final u in selected) {
        final outpoint = dartsv.TransactionOutpoint(
          u.txid,
          u.vout,
          u.valueSats,
          lockingScript,
        );
        builder.spendFromOutpointWithSigner(
          signer,
          outpoint,
          dartsv.TransactionInput.MAX_SEQ_NUMBER,
          dartsv.P2PKHUnlockBuilder(pubKey),
        );
      }

      final tx = builder.build(true);
      return tx.serialize();
    }

    throw Exception('Недостаточно BTC для отправки с учётом комиссии сети.');
  }

  /// Отправляет raw tx (hex) в сеть через blockstream.
  ///
  /// `POST /api/tx` → возвращает txid строкой.
  Future<String> broadcastRawTransactionHex(String rawTxHex) async {
    final trimmed = rawTxHex.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(rawTxHex, 'rawTxHex', 'should not be empty');
    }

    final uri = Uri.https('blockstream.info', '/api/tx');
    final res = await _httpClient.post(
      uri,
      headers: _textHeaders,
      body: trimmed,
    );
    if (res.statusCode != 200) {
      throw StateError(
        'Ошибка отправки BTC-транзакции (${res.statusCode}): ${res.body}',
      );
    }
    final txid = res.body.trim();
    if (txid.isEmpty) {
      throw StateError('BTC-транзакция отправлена, но txid не получен');
    }
    return txid;
  }

  /// Оценка размера/комиссии для legacy P2PKH.
  ///
  /// Приближение (байты): 10 + 148*inputs + 34*outputs
  static BigInt _estimateP2pkhFeeSats({
    required int inputs,
    required int outputs,
    required int feeRateSatsPerVbyte,
  }) {
    final vbytes = 10 + (148 * inputs) + (34 * outputs);
    final fee = BigInt.from(vbytes) * BigInt.from(feeRateSatsPerVbyte);
    return fee <= BigInt.zero ? BigInt.from(1) : fee;
  }

  void dispose() {
    _httpClient.close();
  }
}

class _BtcUtxo {
  _BtcUtxo({required this.txid, required this.vout, required this.valueSats});

  final String txid;
  final int vout;
  final BigInt valueSats;
}
