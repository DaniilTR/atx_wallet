import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/wallet_scope.dart';
import '../../services/auth_scope.dart';

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
  late bool _useDarkTheme;

  @override
  void initState() {
    super.initState();
    _useDarkTheme = widget.themeMode != ThemeMode.light;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final wallet = WalletScope.maybeOf(context);
    final address = wallet?.activeProfile?.addressHex;
    final username = auth.currentUser?.username ?? '—';
    final userId = auth.currentUser?.id;

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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: (wallet == null || userId == null)
                ? null
                : () async {
                    final controller = TextEditingController();
                    try {
                      final password = await showDialog<String>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Подтверждение паролем'),
                            content: TextField(
                              controller: controller,
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: const InputDecoration(
                                labelText: 'Пароль',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(null),
                                child: const Text('Отмена'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(controller.text),
                                child: const Text('Показать'),
                              ),
                            ],
                          );
                        },
                      );

                      final trimmed = password?.trim() ?? '';
                      if (trimmed.isEmpty) return;

                      final seed = await wallet.revealActiveMnemonic(
                        userId: userId,
                        password: trimmed,
                      );
                      if (!context.mounted) return;

                      await showDialog<void>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Ваша seed-фраза'),
                            content: SelectableText(
                              seed,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                height: 1.4,
                              ),
                            ),
                            actions: [
                              TextButton.icon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: seed),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Seed-фраза скопирована'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('Скопировать'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Закрыть'),
                              ),
                            ],
                          );
                        },
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Не удалось открыть seed: $e')),
                      );
                    } finally {
                      controller.dispose();
                    }
                  },
            icon: const Icon(Icons.visibility),
            label: const Text('Показать seed-фразу'),
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
