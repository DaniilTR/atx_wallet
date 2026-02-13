import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../providers/wallet_scope.dart';
import '../../services/auth_scope.dart';
import '../../services/config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.themeMode,
    required this.onThemeChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  late bool _useDarkTheme;

  @override
  void initState() {
    super.initState();
    _controller.text = ApiConfig.base;
    _useDarkTheme = widget.themeMode != ThemeMode.light;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ApiConfig.setBase(_controller.text.trim());
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final wallet = WalletScope.maybeOf(context);
    final address = wallet?.activeProfile?.addressHex;
    final username = auth.currentUser?.username ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _useDarkTheme,
            title: const Text('Темная тема'),
            subtitle: const Text('Переключить между темной и светлой темой'),
            onChanged: (value) {
              setState(() => _useDarkTheme = value);
              widget.onThemeChanged(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(height: 28),
          const Text(
            'Профиль кошелька',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _InfoTile(label: 'Никнейм', value: username),
          const SizedBox(height: 10),
          _InfoTile(
            label: 'Адрес (публичный)',
            value: address ?? '—',
            isMonospace: true,
          ),
          const Divider(height: 28),
          const Text(
            'Подключение к ПК',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/mobile/pair',
                    );
                    if (result is Map) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Сессия получена, подключаемся...'),
                        ),
                      );
                      try {
                        // Отправляем сессию на бэкенд
                        final session = result['session'] as String?;
                        if (session != null) {
                          final uri = ApiConfig.apiUri('/api/pairings');
                          final payload = <String, dynamic>{'session': session};
                          // Если есть адрес, добавляем его
                          final sentAddress =
                              result['address'] as String? ?? address;
                          if (sentAddress != null)
                            payload['address'] = sentAddress;
                          await http.post(
                            uri,
                            body: jsonEncode(payload),
                            headers: {'Content-Type': 'application/json'},
                          );
                        }
                      } catch (_) {
                        // игнорируем ошибки
                      }
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Подключить к ПК (QR)'),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Поддержка',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Центр поддержки'),
                  content: const Text(
                    'Нужна помощь? Обращайтесь:\n'
                    'Почта: almuhambetoveset@gmail.com\n'
                    'Телефон: 87716878676',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Центр поддержки'),
          ),
          const Divider(height: 32),
          const Text(
            'API Base URL (for dev/testing)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'http://192.168.1.100:3000',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  _controller.text = kApiBaseUrl;
                },
                child: const Text('Reset to default'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  final String label;
  final String value;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    final textStyle = isMonospace
        ? const TextStyle(fontFamily: 'RobotoMono', fontSize: 14)
        : const TextStyle(fontSize: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        SelectableText(value, style: textStyle),
      ],
    );
  }
}
