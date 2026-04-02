// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'services/auth_scope.dart';
import 'services/auth_controller.dart';
import 'features/settings/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/start_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/home/home_page.dart';
import 'features/home/activity/history_page.dart';
import 'providers/wallet_provider.dart';
import 'providers/wallet_scope.dart';

Future<void> main() async {
  // Global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // "Несоответствие зоны" возникает, когда код выполняется в другой зоне, чем та,
  // в которой был запущен Flutter. Это может привести к проблемам с обработкой ошибок и состоянием приложения.
  // Запуская код внутри одной зоны, мы гарантируем,
  // что все части приложения работают в одном контексте,
  // что улучшает стабильность и предсказуемость поведения.

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final walletProvider = WalletProvider();
      try {
        await walletProvider.init();
      } catch (_) {}
      runApp(AtxWalletApp(walletProvider: walletProvider));
    },
    (Object error, StackTrace stack) {
      if (kDebugMode) {
        debugPrint('Uncaught zone error: $error');
        debugPrint('$stack');
      }
    },
  );
}

class AtxWalletApp extends StatefulWidget {
  const AtxWalletApp({required this.walletProvider, super.key});

  final WalletProvider walletProvider;

  @override
  State<AtxWalletApp> createState() => _AtxWalletAppState();
}

class _AtxWalletAppState extends State<AtxWalletApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthController();
    _auth.addListener(_syncThemeFromAccount);
    _restoreThemeFromSession();
  }

  @override
  void dispose() {
    _auth.removeListener(_syncThemeFromAccount);
    _auth.dispose();
    super.dispose();
  }

  Future<void> _restoreThemeFromSession() async {
    await _auth.tryRestoreSession();
    if (!mounted) return;
    _syncThemeFromAccount();
  }

  void _syncThemeFromAccount() {
    final user = _auth.currentUser;
    final nextMode = user == null
        ? ThemeMode.dark
        : (user.prefersDarkTheme ? ThemeMode.dark : ThemeMode.light);
    if (_themeMode == nextMode) return;
    setState(() => _themeMode = nextMode);
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);

    final user = _auth.currentUser;
    if (user == null) return;
    final prefersDarkTheme = mode != ThemeMode.light;
    if (user.prefersDarkTheme == prefersDarkTheme) return;
    // Сохраняем в аккаунт асинхронно.
    unawaited(_auth.setPrefersDarkTheme(prefersDarkTheme));
  }

  @override
  Widget build(BuildContext context) {
    final colorSchemeDark = ColorScheme.fromSeed(
      seedColor: const Color(0xFF14191E),
      brightness: Brightness.dark,
    );
    final colorSchemeLight = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7A5AF8),
      brightness: Brightness.light,
    );

    final darkTheme = ThemeData(
      colorScheme: colorSchemeDark,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF14191E),
      useMaterial3: true,
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C2233),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorSchemeDark.primary, width: 1.4),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF14191E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );

    final lightTheme = ThemeData(
      colorScheme: colorSchemeLight,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      useMaterial3: true,
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F4FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorSchemeLight.primary, width: 1.6),
        ),
      ),
      dividerColor: const Color(0xFFE6EAF2),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 1,
        shadowColor: const Color(0x1A1B2C5B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF334155)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorSchemeLight.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF4C6BFF)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: Color(0xFF4C6BFF),
        unselectedItemColor: Color(0xFF94A3B8),
        elevation: 0,
      ),
    );

    return MaterialApp(
      title: 'ATX Wallet',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const StartPage(),
        '/start': (_) => const StartPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/market': (_) => const MarketScreen(),
        '/rewards': (_) => const RewardsPage(),
        '/history': (_) => const HistoryPage(),
        '/settings': (_) => SettingsScreen(
          themeMode: _themeMode,
          onThemeChanged: _setThemeMode,
        ),
      },
      builder: (context, child) {
        final actualChild = child ?? const SizedBox.shrink();
        return AuthScope(
          controller: _auth,
          child: WalletScope(
            controller: widget.walletProvider,
            child: actualChild,
          ),
        );
      },
    );
  }
}
