import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:atx_wallet/features/auth/start_page.dart';
import '../../providers/wallet_scope.dart';
import '../../services/auth_scope.dart';
import '../../services/config.dart' as app_config;
import '../home/home_page.dart' show HomeRouteArgs;
import 'widgets/animated_neon_background.dart';
import 'widgets/auth_loading_view.dart';
import 'widgets/glass_card.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agree = false;
  bool _loading = false;
  bool _checkingSession = true;

  Future<void> _openLegalUrl(String url, String label) async {
    if (url.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ссылка "$label" не настроена')));
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Некорректная ссылка "$label"')));
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось открыть "$label"')));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptPrefill());
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _attemptPrefill() async {
    final auth = AuthScope.of(context);
    try {
      final user = await auth.tryRestoreSession();
      if (!mounted) return;
      if (user == null) {
        setState(() => _checkingSession = false);
        return;
      }
      // Если сессия восстановлена, регистрации обычно не нужно.
      // Оставляем экран регистрации, но заполняем никнейм.
      _usernameCtrl.text = user.username;
      setState(() => _checkingSession = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingSession = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Подтвердите согласие с условиями и политикой'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final auth = AuthScope.of(context);
    final wallet = WalletScope.read(context);
    try {
      final user = await auth.register(
        username: _usernameCtrl.text.trim(),
        email: null,
        password: _passwordCtrl.text,
      );
      await wallet.createInitialSecureWallet(
        userId: user.id,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: HomeRouteArgs(userId: user.id),
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
      return const AuthLoadingView(message: 'Готовим аккаунт...');
    }
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    OutlineInputBorder _inputBorder(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: 1),
    );

    InputDecoration _fieldDecoration({
      required String label,
      required Widget prefixIcon,
      Widget? suffixIcon,
    }) {
      final baseFill = isDark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.black.withValues(alpha: 0.06);
      final baseBorder = isDark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.black.withValues(alpha: 0.10);
      final focusedBorder = isDark
          ? Colors.white.withValues(alpha: 0.28)
          : Colors.black.withValues(alpha: 0.18);

      return InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: baseFill,
        enabledBorder: _inputBorder(baseBorder),
        focusedBorder: _inputBorder(focusedBorder),
        border: _inputBorder(baseBorder),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          AnimatedNeonBackground(isDark: isDark),
          if (isDark) ...const [
            Positioned(
              top: -40,
              right: -10,
              child: _GlowCircle(
                diameter: 240,
                color: Color.fromARGB(255, 125, 71, 250),
                opacity: 0.85,
              ),
            ),
            Positioned(
              top: 260,
              left: -80,
              child: _GlowCircle(
                diameter: 220,
                color: Color.fromARGB(255, 47, 56, 179),
                opacity: 0.75,
              ),
            ),
            Positioned(
              top: 580,
              right: -20,
              child: _GlowCircle(
                diameter: 240,
                color: Color.fromARGB(255, 96, 219, 250),
                opacity: 0.75,
              ),
            ),
          ],
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  left: 8,
                  child: _BackButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const StartPage(),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned(
                            top: -110,
                            right: -50,
                            child: IgnorePointer(child: _RegisterDecoration()),
                          ),
                          GlassCard(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            borderRadius: 18,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _Header(
                                    title: 'Регистрация',
                                    subtitle: 'Создайте свой кошелёк ATX',
                                    center: true,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _usernameCtrl,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) => FocusScope.of(
                                      context,
                                    ).requestFocus(_passwordFocus),
                                    decoration: _fieldDecoration(
                                      label: 'Никнейм',
                                      prefixIcon: const Icon(
                                        Icons.alternate_email,
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
                                    focusNode: _passwordFocus,
                                    obscureText: _obscure1,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) => FocusScope.of(
                                      context,
                                    ).requestFocus(_confirmFocus),
                                    decoration: _fieldDecoration(
                                      label: 'Пароль',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure1
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscure1 = !_obscure1,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Введите пароль';
                                      if (v.length < 8)
                                        return 'Минимум 8 символов';
                                      if (!RegExp(
                                        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*#?&]).{8,}$',
                                      ).hasMatch(v)) {
                                        return 'Пароль должен содержать Заглавные и \n строчные буквы, цифры и спецсимволы';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _confirmCtrl,
                                    focusNode: _confirmFocus,
                                    obscureText: _obscure2,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) =>
                                        _loading ? null : _submit(),
                                    decoration: _fieldDecoration(
                                      label: 'Подтверждение пароля',
                                      prefixIcon: const Icon(
                                        Icons.lock_person_outlined,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure2
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscure2 = !_obscure2,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v != _passwordCtrl.text)
                                        return 'Пароли не совпадают';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _agree,
                                        onChanged: _loading
                                            ? null
                                            : (v) => setState(
                                                () => _agree = v ?? false,
                                              ),
                                      ),
                                      Expanded(
                                        child: Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            const Text('Я согласен с '),
                                            TextButton(
                                              onPressed: _loading
                                                  ? null
                                                  : () => _openLegalUrl(
                                                      app_config.kTermsOfUseUrl,
                                                      'Условия использования',
                                                    ),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 0),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              child: const Text(
                                                'Условиями использования',
                                              ),
                                            ),
                                            const Text(' и '),
                                            TextButton(
                                              onPressed: _loading
                                                  ? null
                                                  : () => _openLegalUrl(
                                                      app_config
                                                          .kPrivacyPolicyUrl,
                                                      'Политика конфиденциальности',
                                                    ),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 0),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              child: const Text(
                                                'Политикой конфиденциальности',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: _loading ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                                        : const Text('Создать аккаунт'),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Уже есть аккаунт?'),
                                      const SizedBox(width: 100),
                                      TextButton(
                                        onPressed: _loading
                                            ? null
                                            : () =>
                                                  Navigator.pushReplacementNamed(
                                                    context,
                                                    '/login',
                                                  ),
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
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    this.center = false,
  });
  final String title;
  final String subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.diameter,
    required this.color,
    this.opacity = 0.55,
  });

  final double diameter;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterDecoration extends StatelessWidget {
  const _RegisterDecoration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/3d_object_2.png',
      width: 150,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Назад',
      ),
    );
  }
}
