import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import '../../services/config.dart';

import '../../services/session_service.dart';
import '../../providers/wallet_scope.dart';

class DesktopPairingScreen extends StatefulWidget {
  const DesktopPairingScreen({super.key});

  @override
  State<DesktopPairingScreen> createState() => _DesktopPairingScreenState();
}

class _DesktopPairingScreenState extends State<DesktopPairingScreen> {
  late final SessionService _session;
  Timer? _ticker;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _session = SessionService.instance;
    _session.rotate();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // If token expired, rotate once and update UI; otherwise just update countdown
      if (_session.isExpired) {
        _session.rotate();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR истёк — обновлён')));
      } else {
        setState(() {});
      }
    });
    // Start polling pairing status for the current session (dev flow)
    _poller = Timer.periodic(const Duration(seconds: 2), (_) async {
      final session = _session.token;
      if (session.isEmpty || _session.isExpired) return;
      try {
        final uri = ApiConfig.apiUri('/api/pairings/$session');
        final res = await http.get(uri).timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          // parse optional address and set read-only profile so desktop shows address/balances
          try {
            final map = res.body.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(res.body) as Map) : {};
            final addr = map['address'] as String?;
            if (addr != null && addr.isNotEmpty) {
              try {
                final wallet = WalletScope.of(context);
                await wallet.setReadOnlyAddress(addr);
              } catch (_) {}
            }
          } catch (_) {}
          // paired — navigate to dashboard
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Телефон подключён')));
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/desktop/dashboard');
        }
      } catch (_) {
        // ignore
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _poller?.cancel();
    super.dispose();
  }

  String _countdown() {
    final until = _session.expiresAt;
    if (until == null) return '';
    final diff = until.difference(DateTime.now());
    final secs = diff.inSeconds.clamp(0, 5 * 60);
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expired = _session.isExpired;
    final qrData = _session.buildQrPayload();

    // no debug prints in production UI

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Подключение телефона',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Откройте ATX Wallet на телефоне и выберите «Подключить к ПК». Сканируйте QR-код ниже. Приватные ключи остаются только на телефоне.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  color: const Color(0xFF1A2030),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: qrData.trim().isEmpty
                              ? SizedBox(
                                  width: 260,
                                  height: 260,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.qr_code_2, size: 48, color: Colors.black26),
                                        SizedBox(height: 8),
                                        Text('QR отсутствует', style: TextStyle(color: Colors.black38)),
                                      ],
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () => _showFullScreenQr(context, qrData),
                                  child: QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    size: 260,
                                    eyeStyle: QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black,
                                    ),
                                    dataModuleStyle: QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              expired ? Icons.timer_off : Icons.timer,
                              size: 18,
                              color: expired ? Colors.redAccent : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              expired ? 'Истёк' : 'Действует: ${_countdown()}',
                              style: TextStyle(
                                color: expired ? Colors.redAccent : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Action buttons: place them immediately after QR/countdown so
                        // they're visible without needing to resize the window.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: () {
                                _session.rotate();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR обновлён')));
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Обновить QR'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () async {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Проверяю подключение...')));
                                final session = _session.token;
                                try {
                                  final uri = ApiConfig.apiUri('/api/pairings/$session');
                                  final res = await http.get(uri).timeout(const Duration(seconds: 3));
                                  if (res.statusCode == 200) {
                                    try {
                                      final map = res.body.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(res.body) as Map) : {};
                                      final addr = map['address'] as String?;
                                      if (addr != null && addr.isNotEmpty) {
                                        final wallet = WalletScope.of(context);
                                        await wallet.setReadOnlyAddress(addr);
                                      }
                                    } catch (_) {}
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Телефон подключён')));
                                    await Future.delayed(const Duration(milliseconds: 250));
                                    if (!mounted) return;
                                    Navigator.pushReplacementNamed(context, '/desktop/dashboard');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Телефон не подключён')));
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка проверки: $e')));
                                }
                              },
                              child: const Text('Я подключил телефон'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Show short session id and copy button for debugging
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Session: ${_session.token.substring(0, 8)}... ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                            ),
                            IconButton(
                              tooltip: 'Copy full session to clipboard',
                              onPressed: () async {
                                try {
                                  await Clipboard.setData(ClipboardData(text: _session.token));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session скопирован')));
                                } catch (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось скопировать')));
                                }
                              },
                              icon: const Icon(Icons.copy, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // raw payload hidden in normal UI
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security, color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'ПК не хранит приватные ключи. Все подписи выполняются на телефоне.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenQr(BuildContext context, String data) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1720),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: data,
                size: 420,
                version: QrVersions.auto,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.white,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
