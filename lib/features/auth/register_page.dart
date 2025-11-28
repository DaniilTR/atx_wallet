import 'package:flutter/material.dart';
import '../../services/auth_scope.dart';
import 'widgets/animated_neon_background.dart';
import 'widgets/glass_card.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agree = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Подтвердите согласие с правилами')),
      );
      return;
    }
    setState(() => _loading = true);
    final auth = AuthScope.of(context);
    try {
      await auth.register(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const _Header(title: 'Регистрация', subtitle: 'Создайте свой кошелёк ATX'),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _usernameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Никнейм',
                                prefixIcon: const Icon(Icons.alternate_email),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                enabledBorder: _glassBorder(Colors.white.withOpacity(0.15)),
                                focusedBorder: _glassBorder(Colors.white.withOpacity(0.35)),
                                border: _glassBorder(Colors.white.withOpacity(0.15)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Введите никнейм';
                                if (v.trim().length < 3) return 'Минимум 3 символа';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Почта',
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                enabledBorder: _glassBorder(Colors.white.withOpacity(0.15)),
                                focusedBorder: _glassBorder(Colors.white.withOpacity(0.35)),
                                border: _glassBorder(Colors.white.withOpacity(0.15)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Введите почту';
                                if (!v.contains('@')) return 'Неверный формат почты';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure1,
                              decoration: InputDecoration(
                                labelText: 'Пароль',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                enabledBorder: _glassBorder(Colors.white.withOpacity(0.15)),
                                focusedBorder: _glassBorder(Colors.white.withOpacity(0.35)),
                                border: _glassBorder(Colors.white.withOpacity(0.15)),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Введите пароль';
                                if (v.length < 6) return 'Минимум 6 символов';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscure2,
                              decoration: InputDecoration(
                                labelText: 'Подтверждение пароля',
                                prefixIcon: const Icon(Icons.lock_person_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                enabledBorder: _glassBorder(Colors.white.withOpacity(0.15)),
                                focusedBorder: _glassBorder(Colors.white.withOpacity(0.35)),
                                border: _glassBorder(Colors.white.withOpacity(0.15)),
                              ),
                              validator: (v) {
                                if (v != _passwordCtrl.text) return 'Пароли не совпадают';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: _agree,
                                  onChanged: (v) => setState(() => _agree = v ?? false),
                                ),
                                const Expanded(child: Text('Согласен с условиями использования')),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                backgroundColor: cs.primary,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Создать аккаунт'),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Уже есть аккаунт?'),
                                TextButton(
                                  onPressed:
                                      _loading ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                                  child: const Text('Войти'),
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
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
      ],
    );
  }
}
