import 'dart:async';
import 'dart:convert';

import 'package:atx_wallet/features/auth/start_page.dart';
import 'package:cryptography/cryptography.dart' show SecretKey;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/wallet_scope.dart';
import '../../services/auth_scope.dart';
import '../../biometrics/biometric_face.dart';
import '../../services/biometric_prefs.dart';
import '../home/home_page.dart' show HomeRouteArgs;
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
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  bool _checkingSession = true;
  bool _biometricAvailable = false;
  String? _biometricUserId;
  Timer? _bioDebounce;
  bool _autoBioInFlight = false;
  String? _lastAutoBioLogin;
  late final _LoginLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _LoginLifecycleObserver(
      onResumed: _onAppResumed,
      onBackgrounded: _onAppBackgrounded,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _loginCtrl.addListener(() {
      final current = _loginCtrl.text.trim();
      if (_lastAutoBioLogin != null && current != _lastAutoBioLogin) {
        _lastAutoBioLogin = null;
      }
      _scheduleCheckBiometrics(allowAutoPrompt: false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptPrefillLogin();
      _scheduleCheckBiometrics(allowAutoPrompt: true);
    });
  }

  void _onAppBackgrounded() {
    _autoBioInFlight = false;
    _lastAutoBioLogin = null;
    if (kDebugMode) {
      debugPrint('[LoginPage] app backgrounded: reset auto-bio guard');
    }
  }

  void _onAppResumed() {
    if (kDebugMode) {
      debugPrint('[LoginPage] app resumed');
    }
    _scheduleCheckBiometrics(allowAutoPrompt: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _bioDebounce?.cancel();
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _scheduleCheckBiometrics({required bool allowAutoPrompt}) {
    _bioDebounce?.cancel();
    final capturedAllowAutoPrompt = allowAutoPrompt;
    _bioDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _checkBiometrics(allowAutoPrompt: capturedAllowAutoPrompt);
    });
  }

  Future<void> _checkBiometrics({required bool allowAutoPrompt}) async {
    try {
      final avail = await BiometricFace.isAvailable();
      final loginName = _loginCtrl.text.trim();

      final auth = AuthScope.of(context);

      // Button visibility should not depend on per-user biometric setup.
      // We still try to resolve the best userId to pass to native code.
      String? resolvedId;
      if (loginName.isNotEmpty) {
        resolvedId =
            await BiometricPrefs.getUserIdForUsername(loginName) ??
            await auth.findUserIdByUsername(loginName);
      }
      final last = await BiometricPrefs.getLastUser();

      final shouldAutoPrompt =
          allowAutoPrompt &&
          avail &&
          loginName.isNotEmpty &&
          resolvedId != null;

      if (kDebugMode) {
        debugPrint(
          '[LoginPage] checkBio allowAuto=$allowAutoPrompt avail=$avail login="$loginName" resolvedId=$resolvedId '
          'checkingSession=$_checkingSession loading=$_loading lastAuto=$_lastAutoBioLogin',
        );
      }

      if (!mounted) return;
      setState(() {
        _biometricAvailable = avail;
        _biometricUserId = avail
            ? (resolvedId ?? (loginName.isNotEmpty ? loginName : last))
            : null;
      });

      if (shouldAutoPrompt) {
        await _maybeAutoBiometricLogin(
          loginName: loginName,
          userId: resolvedId,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _biometricAvailable = false);
    }
  }

  Future<void> _maybeAutoBiometricLogin({
    required String loginName,
    required String userId,
  }) async {
    if (!mounted) return;
    if (_autoBioInFlight || _loading || _checkingSession) return;
    if (!_biometricAvailable) return;
    if (_loginCtrl.text.trim() != loginName) return;
    if (_lastAutoBioLogin == loginName) return;

    _autoBioInFlight = true;
    _lastAutoBioLogin = loginName;
    try {
      if (!mounted) return;
      if (_loginCtrl.text.trim() != loginName) return;

      await _biometricLogin(auto: true);
    } finally {
      _autoBioInFlight = false;
    }
  }

  Future<void> _biometricLogin({bool auto = false}) async {
    final auth = AuthScope.of(context);
    final wallet = WalletScope.read(context);
    final loginName = _loginCtrl.text.trim();

    final mappedUserId = loginName.isEmpty
        ? null
        : await BiometricPrefs.getUserIdForUsername(loginName);
    final resolvedFromAuth = loginName.isEmpty
        ? null
        : await auth.findUserIdByUsername(loginName);

    final lastUserId = await BiometricPrefs.getLastUser();
    final primaryUserId =
        mappedUserId ??
        resolvedFromAuth ??
        _biometricUserId ??
        (loginName.isEmpty ? lastUserId : loginName);

    try {
      setState(() => _loading = true);

      dynamic res;
      try {
        res = await BiometricFace.authenticate(userId: primaryUserId);
      } on PlatformException catch (e) {
        if (e.code == 'no_wrapped_dek' &&
            lastUserId != null &&
            lastUserId.isNotEmpty &&
            lastUserId != primaryUserId) {
          // If userId resolution failed (e.g., username passed), try last known userId.
          res = await BiometricFace.authenticate(userId: lastUserId);
        } else {
          rethrow;
        }
      }

      if (res == null) {
        // User cancelled or biometric didn't complete: treat as a normal outcome.
        return;
      }

      if (res is Map &&
          (res['vaultKeyB64'] is String || res['secretB64'] is String)) {
        final vaultKeyB64 =
            (res['vaultKeyB64'] as String?) ?? (res['secretB64'] as String?);
        if (vaultKeyB64 == null || vaultKeyB64.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Биометрия не вернула ключ разблокировки'),
            ),
          );
          return;
        }

        final vaultKey = SecretKey(base64Decode(vaultKeyB64));

        var usernameToUse = loginName;
        if (usernameToUse.isEmpty) {
          final restored = await auth.tryRestoreSession();
          if (restored == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Введите никнейм для входа по биометрии'),
              ),
            );
            return;
          }
          usernameToUse = restored.username;
          _loginCtrl.text = usernameToUse;
        }

        final user = await auth.loginWithBiometrics(username: usernameToUse);
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Пользователь не найден на устройстве'),
            ),
          );
          return;
        }

        await wallet.unlockSecureWalletsWithKey(userId: user.id, key: vaultKey);
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: HomeRouteArgs(userId: user.id),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Биометрия прошла, но ключ не получен. Включите быстрый вход заново.',
          ),
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'biometric_migration_required') {
        // Migration is actionable even for auto-trigger.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Биометрию нужно включить заново в настройках'),
          ),
        );
      } else if (e.code == 'no_wrapped_dek') {
        // If auto-triggered and biometrics aren't enabled for this user, stay silent.
        if (!auto) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Биометрия не включена для этого пользователя'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка биометрии: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка биометрии: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _attemptPrefillLogin() async {
    final auth = AuthScope.of(context);
    try {
      final user = await auth.tryRestoreSession();
      if (!mounted) return;
      if (user == null) {
        setState(() => _checkingSession = false);
        _scheduleCheckBiometrics(allowAutoPrompt: true);
        return;
      }
      // Безопасный режим: сессия пользователя может быть восстановлена,
      // но кошелёк остаётся заблокирован до ввода пароля.
      _loginCtrl.text = user.username;
      setState(() => _checkingSession = false);
      _scheduleCheckBiometrics(allowAutoPrompt: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingSession = false);
      _scheduleCheckBiometrics(allowAutoPrompt: true);
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
      await wallet.unlockSecureWallets(
        userId: user.id,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: HomeRouteArgs(userId: user.id),
      ); // это
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
                  top: 12,
                  left: 10,
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
                            top: -120,
                            right: -40,
                            child: IgnorePointer(child: _ShellDecoration()),
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
                                    title: 'Войти в кошелек',
                                    subtitle: 'Добро пожаловать в ATX Wallet',
                                    center: true,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _loginCtrl,
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
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) =>
                                        _loading ? null : _submit(),
                                    decoration: _fieldDecoration(
                                      label: 'Пароль',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Введите пароль';
                                      if (v.length < 8)
                                        return 'Минимум 8 символов';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
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
                                        : const Text('Войти'),
                                  ),
                                  if (_biometricAvailable) ...[
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _loading
                                          ? null
                                          : () => _biometricLogin(),
                                      icon: const Icon(Icons.fingerprint),
                                      label: const Text('Войти по биометрии'),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 6,
                                    children: [
                                      const Text('Нет аккаунта?'),
                                      TextButton(
                                        onPressed: _loading
                                            ? null
                                            : () =>
                                                  Navigator.pushReplacementNamed(
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
          ),
        ],
      ),
    );
  }
}

class _LoginLifecycleObserver with WidgetsBindingObserver {
  _LoginLifecycleObserver({
    required this.onResumed,
    required this.onBackgrounded,
  });

  final void Function() onResumed;
  final void Function() onBackgrounded;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      onBackgrounded();
    }
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

class _ShellDecoration extends StatelessWidget {
  const _ShellDecoration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/gradient glass (21).png',
      width: 170,
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
