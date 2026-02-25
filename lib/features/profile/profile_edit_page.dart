import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/wallet_scope.dart';
import '../../services/auth_scope.dart';
import 'profile_prefs.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final auth = AuthScope.of(context);
    _nameCtrl.text =
        ProfilePrefs.displayName ?? auth.currentUser?.username ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _copy(BuildContext context, String label, String value) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label скопирован')));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ProfilePrefs.setDisplayName(_nameCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final wallet = WalletScope.maybeOf(context);
    final user = auth.currentUser;
    final active = wallet?.activeProfile;

    final username = user?.username ?? '—';
    final email = user?.email ?? '—';
    final userId = user?.id ?? '—';
    final walletName = active?.name ?? '—';
    final address = active?.addressHex ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование профиля')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 34,
              child: Text(
                (_nameCtrl.text.trim().isEmpty
                        ? username
                        : _nameCtrl.text.trim())
                    .characters
                    .first
                    .toUpperCase(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.done,
            maxLength: 24,
            decoration: const InputDecoration(
              labelText: 'Отображаемое имя',
              hintText: 'Как показывать вас в приложении',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Сохранить'),
          ),
          const Divider(height: 28),
          const Text(
            'Данные аккаунта',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _InfoLine(label: 'Никнейм', value: username),
          const SizedBox(height: 8),
          _InfoLine(label: 'Email', value: email),
          const SizedBox(height: 8),
          _InfoLine(
            label: 'User ID',
            value: userId,
            trailing: IconButton(
              tooltip: 'Копировать ID',
              onPressed: userId == '—'
                  ? null
                  : () => _copy(context, 'ID', userId),
              icon: const Icon(Icons.copy_rounded),
            ),
          ),
          const Divider(height: 28),
          const Text(
            'Кошелёк',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _InfoLine(label: 'Активный кошелёк', value: walletName),
          const SizedBox(height: 8),
          _InfoLine(
            label: 'Публичный адрес',
            value: address,
            isMonospace: true,
            trailing: IconButton(
              tooltip: 'Копировать адрес',
              onPressed: address == '—'
                  ? null
                  : () => _copy(context, 'Адрес', address),
              icon: const Icon(Icons.copy_rounded),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              wallet?.clearDevProfile();
              await auth.logout();
              if (!mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/start', (_) => false);
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.trailing,
    this.isMonospace = false,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: isMonospace
                    ? const TextStyle(fontFamily: 'RobotoMono', fontSize: 14)
                    : const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
