import 'dart:math' as math;

import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'config.dart';

class UniswapV2RouterService {
  UniswapV2RouterService({required Web3Client client}) : _client = client;

  final Web3Client _client;

  static final ContractAbi _abi = ContractAbi.fromJson(
    _uniswapV2RouterAbiJson,
    'UniswapV2Router02',
  );

  EthereumAddress get routerAddress => _routerForChainId(kEvmChainId);

  EthereumAddress get wethAddress => _wethForChainId(kEvmChainId);

  DeployedContract _router() => DeployedContract(_abi, routerAddress);

  /// Ensures router address is supported and has bytecode.
  Future<void> assertRouterReady() async {
    final code = await _client.getCode(routerAddress);
    if (code.isEmpty) {
      throw StateError('Router contract code not found for current network');
    }
  }

  Future<List<BigInt>> getAmountsOut({
    required BigInt amountIn,
    required List<EthereumAddress> path,
  }) async {
    final router = _router();
    final fn = router.function('getAmountsOut');
    final res = await _client.call(
      contract: router,
      function: fn,
      params: [amountIn, path],
    );
    final amounts = res.first as List<dynamic>;
    return amounts.cast<BigInt>();
  }

  /// Executes a swap.
  ///
  /// - For ETH -> ERC20 use [swapExactETHForTokens].
  /// - For ERC20 -> ETH use [swapExactTokensForETH].
  /// - For ERC20 -> ERC20 use [swapExactTokensForTokens].
  ///
  /// Returns tx hash (or signed tx hex if `kColdWalletMode == true`).
  Future<String> swapExactETHForTokens({
    required String privateKeyHex,
    required BigInt amountInWei,
    required BigInt amountOutMin,
    required List<EthereumAddress> path,
    required EthereumAddress recipient,
    required BigInt deadline,
  }) async {
    return _sendSwapTx(
      privateKeyHex: privateKeyHex,
      functionName: 'swapExactETHForTokens',
      parameters: [amountOutMin, path, recipient, deadline],
      value: EtherAmount.fromUnitAndValue(EtherUnit.wei, amountInWei),
    );
  }

  Future<String> swapExactTokensForETH({
    required String privateKeyHex,
    required BigInt amountIn,
    required BigInt amountOutMin,
    required List<EthereumAddress> path,
    required EthereumAddress recipient,
    required BigInt deadline,
  }) async {
    return _sendSwapTx(
      privateKeyHex: privateKeyHex,
      functionName: 'swapExactTokensForETH',
      parameters: [amountIn, amountOutMin, path, recipient, deadline],
    );
  }

  Future<String> swapExactTokensForTokens({
    required String privateKeyHex,
    required BigInt amountIn,
    required BigInt amountOutMin,
    required List<EthereumAddress> path,
    required EthereumAddress recipient,
    required BigInt deadline,
  }) async {
    return _sendSwapTx(
      privateKeyHex: privateKeyHex,
      functionName: 'swapExactTokensForTokens',
      parameters: [amountIn, amountOutMin, path, recipient, deadline],
    );
  }

  Future<String> _sendSwapTx({
    required String privateKeyHex,
    required String functionName,
    required List<dynamic> parameters,
    EtherAmount? value,
  }) async {
    if (kEvmChainId != 1) {
      throw StateError(
        'Uniswap V2 Router is only allowlisted for Ethereum Mainnet (chainId=1) in this project',
      );
    }

    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final from = credentials.address;

    final router = _router();
    final fn = router.function(functionName);

    final call = Transaction.callContract(
      contract: router,
      function: fn,
      parameters: parameters,
      value: value,
    );

    final gas = await _client.estimateGas(
      sender: from,
      to: routerAddress,
      value: value,
      data: call.data,
    );

    final gasPrice = await _client.getGasPrice();

    final tx = Transaction(
      to: routerAddress,
      data: call.data,
      value: value,
      gasPrice: gasPrice,
      maxGas: _bufferGas(gas),
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

  int _bufferGas(BigInt estimated) {
    final base = estimated.toInt();
    final buffered = (base * 1.2).ceil();
    return math.min(1500000, math.max(200000, buffered));
  }
}

EthereumAddress _routerForChainId(int chainId) {
  // Uniswap V2 Router02 on Ethereum Mainnet.
  if (chainId == 1) {
    // Use lowercase to avoid EIP-55 checksum validation issues.
    return EthereumAddress.fromHex('0x7a250d5630b4cf539739df2c5dacb4c659f2488d');
  }
  throw StateError('Unsupported chainId for Uniswap V2 Router in allowlist: $chainId');
}

EthereumAddress _wethForChainId(int chainId) {
  // WETH on Ethereum Mainnet.
  if (chainId == 1) {
    // Use lowercase to avoid EIP-55 checksum validation issues.
    return EthereumAddress.fromHex('0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2');
  }
  throw StateError('Unsupported chainId for WETH in allowlist: $chainId');
}

const String _uniswapV2RouterAbiJson = '''[
  {"name":"getAmountsOut","type":"function","stateMutability":"view","inputs":[{"name":"amountIn","type":"uint256"},{"name":"path","type":"address[]"}],"outputs":[{"name":"amounts","type":"uint256[]"}]},
  {"name":"swapExactETHForTokens","type":"function","stateMutability":"payable","inputs":[{"name":"amountOutMin","type":"uint256"},{"name":"path","type":"address[]"},{"name":"to","type":"address"},{"name":"deadline","type":"uint256"}],"outputs":[{"name":"amounts","type":"uint256[]"}]},
  {"name":"swapExactTokensForETH","type":"function","stateMutability":"nonpayable","inputs":[{"name":"amountIn","type":"uint256"},{"name":"amountOutMin","type":"uint256"},{"name":"path","type":"address[]"},{"name":"to","type":"address"},{"name":"deadline","type":"uint256"}],"outputs":[{"name":"amounts","type":"uint256[]"}]},
  {"name":"swapExactTokensForTokens","type":"function","stateMutability":"nonpayable","inputs":[{"name":"amountIn","type":"uint256"},{"name":"amountOutMin","type":"uint256"},{"name":"path","type":"address[]"},{"name":"to","type":"address"},{"name":"deadline","type":"uint256"}],"outputs":[{"name":"amounts","type":"uint256[]"}]}
]''';
