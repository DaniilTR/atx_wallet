import 'package:flutter/material.dart';
import '../../dev/dev_wallet_storage.dart';
import '../../providers/wallet_scope.dart';
import '../../services/auth_scope.dart';
import '../home/home_route_args.dart';
import 'widgets/animated_neon_background.dart';
import 'widgets/auth_loading_view.dart';
import 'widgets/glass_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptAutoLogin());
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _attemptAutoLogin() async {
    final auth = AuthScope.of(context);
    final wallet = WalletScope.read(context);
    try {
      final user = await auth.tryRestoreSession();
      if (!mounted) return;
      if (user == null) {
        setState(() => _checkingSession = false);
        return;
      }
      DevWalletProfile? profile;
      if (wallet.devEnabled) {
        try {
          profile = await wallet.loadDevProfile(user.id);
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: HomeRouteArgs(userId: user.id, devProfile: profile),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingSession = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = AuthScope.of(context);
    final wallet = WalletScope.read(context);
    try {
      final user = await auth.login(
        login: _loginCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      DevWalletProfile? profile;
      if (wallet.devEnabled) {
        profile = await wallet.loadDevProfile(user.id);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: HomeRouteArgs(userId: user.id, devProfile: profile),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const AuthLoadingView(message: 'Проверяем вход...');
    }
    final cs = Theme.of(context).colorScheme;
    OutlineInputBorder _glassBorder(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: 1),
    );

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedNeonBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const _Header(
                      title: 'Вход',
                      subtitle: 'Добро пожаловать в ATX Wallet',
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _loginCtrl,
                              decoration: InputDecoration(
                                labelText: 'Никнейм',
                                prefixIcon: const Icon(Icons.alternate_email),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                enabledBorder: _glassBorder(
                                  Colors.white.withOpacity(0.15),
                                ),
                                focusedBorder: _glassBorder(
                                  Colors.white.withOpacity(0.35),
                                ),
                                border: _glassBorder(
                                  Colors.white.withOpacity(0.15),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Введите никнейм';
                                if (v.trim().length < 3)
                                  return 'Минимум 3 символа';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Пароль',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                enabledBorder: _glassBorder(
                                  Colors.white.withOpacity(0.15),
                                ),
                                focusedBorder: _glassBorder(
                                  Colors.white.withOpacity(0.35),
                                ),
                                border: _glassBorder(
                                  Colors.white.withOpacity(0.15),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Введите пароль';
                                if (v.length < 6) return 'Минимум 6 символов';
                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text('Забыли пароль?'),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: cs.primary,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Войти'),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              children: [
                                const Text('Нет аккаунта?'),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.pushReplacementNamed(
                                          context,
                                          '/register',
                                        ),
                                  child: const Text('Зарегистрироваться'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
