import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:atx_wallet/providers/wallet_scope.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MobilePairConnectScreen extends StatefulWidget {
  const MobilePairConnectScreen({super.key});

  @override
  State<MobilePairConnectScreen> createState() =>
      _MobilePairConnectScreenState();
}

class _MobilePairConnectScreenState extends State<MobilePairConnectScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionTimeoutMs: 550,
  );
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere(
          (v) => v != null && v.trim().isNotEmpty,
          orElse: () => null,
        );
    if (raw == null) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final payload = jsonDecode(raw);
      if (payload is! Map<String, dynamic>)
        throw const FormatException('bad_json');
      if (payload['type'] != 'pair') throw const FormatException('bad_type');
      final session = payload['session'] as String?;
      final relay = payload['relay'] as String?;
      final expiresAt = payload['expiresAt'] as String?;
      if (session == null || relay == null || expiresAt == null) {
        throw const FormatException('missing_fields');
      }
      final exp = DateTime.tryParse(expiresAt);
      if (exp == null || DateTime.now().isAfter(exp)) {
        throw const FormatException('expired');
      }
      if (!mounted) return;
      final wallet = WalletScope.maybeOf(context);
      final addr = wallet?.activeProfile?.addressHex;
      Navigator.pop(context, {
        'session': session,
        'relay': relay,
        'expiresAt': exp.toUtc().toIso8601String(),
        if (addr != null) 'address': addr,
      });
    } catch (e) {
      setState(() {
        _error = 'Неверный или просроченный QR';
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Подключение к ПК')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: _processing
                                ? null
                                : () => _controller.toggleTorch(),
                            icon: const Icon(Icons.bolt),
                            label: const Text('Фонарик'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _processing
                                ? null
                                : () => _controller.switchCamera(),
                            icon: const Icon(Icons.cameraswitch),
                            label: const Text('Сменить камеру'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2030),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.security, color: cs.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Подключение безопасно: приватные ключи остаются на телефоне. QR содержит только параметры сессии.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
