import 'dart:math' as math;

import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'config.dart';

class Erc20Service {
  Erc20Service({required Web3Client client}) : _client = client;

  final Web3Client _client;

  static final ContractAbi _abi = ContractAbi.fromJson(_erc20AbiJson, 'ERC20');

  DeployedContract _contract(EthereumAddress token) {
    return DeployedContract(_abi, token);
  }

  Future<BigInt> allowance({
    required EthereumAddress token,
    required EthereumAddress owner,
    required EthereumAddress spender,
  }) async {
    final contract = _contract(token);
    final fn = contract.function('allowance');
    final res = await _client.call(
      contract: contract,
      function: fn,
      params: [owner, spender],
    );
    return res.first as BigInt;
  }

  /// Sets allowance to [amount].
  ///
  /// Some tokens (notably USDT on mainnet) require first setting allowance to 0
  /// before changing it to a new non-zero value.
  ///
  /// Returns list of tx hashes (1 or 2 transactions).
  Future<List<String>> safeApprove({
    required EthereumAddress token,
    required String privateKeyHex,
    required EthereumAddress spender,
    required BigInt amount,
    required EthereumAddress owner,
  }) async {
    final current = await allowance(
      token: token,
      owner: owner,
      spender: spender,
    );

    final out = <String>[];
    if (current != BigInt.zero && amount != BigInt.zero) {
      out.add(
        await _approve(
          token: token,
          privateKeyHex: privateKeyHex,
          spender: spender,
          amount: BigInt.zero,
        ),
      );
    }
    out.add(
      await _approve(
        token: token,
        privateKeyHex: privateKeyHex,
        spender: spender,
        amount: amount,
      ),
    );
    return out;
  }

  Future<String> _approve({
    required EthereumAddress token,
    required String privateKeyHex,
    required EthereumAddress spender,
    required BigInt amount,
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final from = credentials.address;

    final contract = _contract(token);
    final fn = contract.function('approve');

    final tx = Transaction.callContract(
      contract: contract,
      function: fn,
      parameters: [spender, amount],
    );

    // Estimate gas with a safety buffer.
    final gas = await _client.estimateGas(
      sender: from,
      to: token,
      data: tx.data,
    );
    final buffered = (gas.toInt() * 1.2).ceil();

    final gasPrice = await _client.getGasPrice();

    final finalTx = Transaction(
      to: token,
      data: tx.data,
      maxGas: math.min(200000, math.max(60000, buffered)),
      gasPrice: gasPrice,
    );

    if (kColdWalletMode) {
      final signed = await _client.signTransaction(
        credentials,
        finalTx,
        chainId: kEvmChainId,
      );
      return bytesToHex(signed, include0x: true);
    }

    return _client.sendTransaction(
      credentials,
      finalTx,
      chainId: kEvmChainId,
    );
  }
}

const String _erc20AbiJson = '''[
  {"constant":true,"inputs":[{"name":"owner","type":"address"},{"name":"spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},
  {"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}
]''';
