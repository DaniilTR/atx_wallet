import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';

import 'config.dart';

class BlockchainService {
  BlockchainService({http.Client? httpClient, Web3Client? web3client})
    : _httpClient = httpClient ?? http.Client() {
    _client = web3client ?? Web3Client(kEvmRpcUrl, _httpClient);
  }

  final http.Client _httpClient;
  late final Web3Client _client;

  final Map<String, int> _decimalsCache = <String, int>{};
  final Map<String, DeployedContract> _contractCache =
      <String, DeployedContract>{};

  Web3Client get client => _client;

  Future<EtherAmount> getGasPrice() {
    return _client.getGasPrice();
  }

  Future<BigInt> estimateGasForNativeTransfer({
    required EthereumAddress from,
    required EthereumAddress to,
    required BigInt valueWei,
  }) {
    return _client.estimateGas(
      sender: from,
      to: to,
        value: EtherAmount.fromUnitAndValue(EtherUnit.wei, valueWei),
    );
  }

  Future<BigInt> estimateGasForErc20Transfer({
    required EthereumAddress from,
    required EthereumAddress contract,
    required EthereumAddress to,
    required BigInt amount,
  }) async {
    final deployed = _erc20Contract(contract);
    final tx = Transaction.callContract(
      contract: deployed,
      function: deployed.function('transfer'),
      parameters: [to, amount],
    );
    return _client.estimateGas(sender: from, to: contract, data: tx.data);
  }

  Future<EtherAmount> getNativeBalance(EthereumAddress address) {
    return _client.getBalance(address);
  }

  Future<BigInt> getTokenBalance(
    EthereumAddress contract,
    EthereumAddress holder,
  ) async {
    final deployed = _erc20Contract(contract);
    final response = await _client.call(
      contract: deployed,
      function: deployed.function('balanceOf'),
      params: [holder],
    );
    return response.first as BigInt;
  }

  Future<int> getTokenDecimals(EthereumAddress contract) async {
    final key = contract.hexEip55.toLowerCase();
    final cached = _decimalsCache[key];
    if (cached != null) return cached;
    final deployed = _erc20Contract(contract);
    final response = await _client.call(
      contract: deployed,
      function: deployed.function('decimals'),
      params: const [],
    );
    final decimals = (response.first as BigInt).toInt();
    _decimalsCache[key] = decimals;
    return decimals;
  }

  Future<String> sendNative({
    required String privateKeyHex,
    required EthereumAddress to,
    required EtherAmount amount,
    int? maxGas,
    EtherAmount? gasPrice,
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final tx = Transaction(
      to: to,
      value: amount,
      maxGas: maxGas,
      gasPrice: gasPrice,
    );
    if (kColdWalletMode) {
      final signed = await _client.signTransaction(
        credentials,
        tx,
        chainId: kEvmChainId,
      );
      return bytesToHex(signed, include0x: true);
    }
    return _client.sendTransaction(credentials, tx, chainId: kEvmChainId);
  }

  Future<String> sendToken({
    required String privateKeyHex,
    required EthereumAddress contract,
    required EthereumAddress to,
    required BigInt amount,
    int? maxGas,
    EtherAmount? gasPrice,
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final deployed = _erc20Contract(contract);
    final tx = Transaction.callContract(
      contract: deployed,
      function: deployed.function('transfer'),
      parameters: [to, amount],
      maxGas: maxGas,
      gasPrice: gasPrice,
    );
    if (kColdWalletMode) {
      final signed = await _client.signTransaction(
        credentials,
        tx,
        chainId: kEvmChainId,
      );
      return bytesToHex(signed, include0x: true);
    }
    return _client.sendTransaction(credentials, tx, chainId: kEvmChainId);
  }

  Future<void> dispose() async {
    _httpClient.close();
    await _client.dispose();
  }

  DeployedContract _erc20Contract(EthereumAddress address) {
    final key = address.hexEip55.toLowerCase();
    final cached = _contractCache[key];
    if (cached != null) return cached;
    final contract = DeployedContract(
      ContractAbi.fromJson(_erc20Abi, 'ERC20'),
      address,
    );
    _contractCache[key] = contract;
    return contract;
  }
}

const String _erc20Abi = '''[
  {"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},
  {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},
  {"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}
]''';
