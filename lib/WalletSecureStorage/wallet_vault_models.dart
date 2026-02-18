import 'dart:convert';

class WalletVaultBundle {
  const WalletVaultBundle({
    required this.version,
    required this.createdAtIso,
    required this.kdf,
    required this.activeWalletId,
    required this.wallets,
  });

  final int version;
  final String createdAtIso;
  final WalletVaultKdf kdf;
  final String activeWalletId;
  final List<WalletVaultEntry> wallets;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'v': version,
    'createdAt': createdAtIso,
    'kdf': kdf.toJson(),
    'activeWalletId': activeWalletId,
    'wallets': wallets.map((e) => e.toJson()).toList(growable: false),
  };

  static WalletVaultBundle fromJson(Map<String, dynamic> json) {
    final wallets = (json['wallets'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(WalletVaultEntry.fromJson)
        .toList(growable: false);

    return WalletVaultBundle(
      version: (json['v'] as num?)?.toInt() ?? 1,
      createdAtIso:
          (json['createdAt'] as String?) ??
          DateTime.now().toUtc().toIso8601String(),
      kdf: WalletVaultKdf.fromJson(
        (json['kdf'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      activeWalletId:
          (json['activeWalletId'] as String?) ??
          (wallets.isNotEmpty ? wallets.first.walletId : ''),
      wallets: wallets,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static WalletVaultBundle fromJsonString(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return fromJson(map);
  }
}

class WalletVaultKdf {
  const WalletVaultKdf({
    required this.alg,
    required this.iterations,
    required this.saltB64,
    this.bits = 256,
  });

  final String alg;
  final int iterations;
  final String saltB64;
  final int bits;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'alg': alg,
    'iterations': iterations,
    'saltB64': saltB64,
    'bits': bits,
  };

  static WalletVaultKdf fromJson(Map<String, dynamic> json) {
    return WalletVaultKdf(
      alg: (json['alg'] as String?) ?? 'pbkdf2-hmac-sha256',
      iterations: (json['iterations'] as num?)?.toInt() ?? 210000,
      saltB64: (json['saltB64'] as String?) ?? '',
      bits: (json['bits'] as num?)?.toInt() ?? 256,
    );
  }
}

class WalletVaultEntry {
  const WalletVaultEntry({
    required this.walletId,
    required this.name,
    required this.userId,
    required this.addressHex,
    required this.cipherAlg,
    required this.nonceB64,
    required this.macB64,
    required this.ciphertextB64,
  });

  final String walletId;
  final String name;
  final String userId;
  final String addressHex;
  final String cipherAlg;
  final String nonceB64;
  final String macB64;
  final String ciphertextB64;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'walletId': walletId,
    'name': name,
    'userId': userId,
    'addressHex': addressHex,
    'cipher': <String, dynamic>{
      'alg': cipherAlg,
      'nonceB64': nonceB64,
      'macB64': macB64,
    },
    'ciphertextB64': ciphertextB64,
  };

  static WalletVaultEntry fromJson(Map<String, dynamic> json) {
    final cipher =
        (json['cipher'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return WalletVaultEntry(
      walletId: (json['walletId'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Кошелёк',
      userId: (json['userId'] as String?) ?? '',
      addressHex: (json['addressHex'] as String?) ?? '',
      cipherAlg: (cipher['alg'] as String?) ?? 'aes-256-gcm',
      nonceB64: (cipher['nonceB64'] as String?) ?? '',
      macB64: (cipher['macB64'] as String?) ?? '',
      ciphertextB64: (json['ciphertextB64'] as String?) ?? '',
    );
  }
}
