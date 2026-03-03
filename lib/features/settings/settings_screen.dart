import 'dart:async';

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
                      final isConfirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Что такое seed-фраза?'),
                            content: const Text(
                              'Это резервный ключ для восстановления кошелька.\n'
                              'Мы не храним её и не можем восстановить за вас.\n'
                              'Запишите фразу на бумаге и храните офлайн.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Отмена'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Продолжить'),
                              ),
                            ],
                          );
                        },
                      );

                      if (isConfirmed != true) return;
                      if (!context.mounted) return;

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
                        builder: (context) => _SeedPhraseDialog(seed: seed),
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

class _SeedPhraseDialog extends StatefulWidget {
  const _SeedPhraseDialog({required this.seed});

  final String seed;

  @override
  State<_SeedPhraseDialog> createState() => _SeedPhraseDialogState();
}

class _SeedPhraseDialogState extends State<_SeedPhraseDialog> {
  static const int _timeoutSeconds = 60;

  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _timeoutSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ваша seed-фраза'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Окно закроется через $_secondsLeft сек.'),
          const SizedBox(height: 12),
          SelectableText(
            widget.seed,
            style: const TextStyle(fontFamily: 'monospace', height: 1.4),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: widget.seed));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seed-фраза скопирована')),
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
  }
}
