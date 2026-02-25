import 'dart:async';
import 'package:flutter/material.dart';

import 'services/auth_scope.dart';
import 'services/config.dart';
import 'features/settings/settings_screen.dart';
import 'services/platform.dart';
import 'features/desktop/pairing_screen.dart';
import 'features/desktop/dashboard_screen.dart';
import 'features/desktop/connection_screen/pair_connect_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/start_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/home/home_page.dart';
import 'features/home/activity/history_page.dart';
import 'features/profile/profile_edit_page.dart';
import 'features/profile/profile_prefs.dart';
import 'providers/wallet_provider.dart';
import 'providers/wallet_scope.dart';

Future<void> main() async {
  // Global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Run initialization and app inside the same zone to avoid "Zone mismatch" warnings
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await ApiConfig.init();
      await ProfilePrefs.init();
      final walletProvider = WalletProvider(
        devEnabled: kEnableDevWalletStorage,
      );
      try {
        await walletProvider.init();
      } catch (_) {}
      runApp(AtxWalletApp(walletProvider: walletProvider));
    },
    (Object error, StackTrace stack) {
      // ignore: avoid_print
      print('Uncaught error: $error');
      // ignore: avoid_print
      print(stack);
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

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
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
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
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

    final initialRoute = isDesktop ? '/desktop/pair' : kInitialRoute;
    // Debug: log platform and chosen initial route to help diagnose startup routing
    // (Remove or guard this in production)
    // ignore: avoid_print
    print(
      'AtxWalletApp starting — isDesktop=$isDesktop initialRoute=$initialRoute',
    );

    return MaterialApp(
      title: 'ATX Wallet',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      initialRoute: initialRoute,
      routes: {
        '/start': (_) => const StartPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/market': (_) => const MarketScreen(),
        '/rewards': (_) => const RewardsPage(),
        '/history': (_) => const HistoryPage(),
        '/mobile/pair': (_) => const MobilePairConnectScreen(),
        '/desktop/pair': (_) => const DesktopPairingScreen(),
        '/desktop/dashboard': (_) => const DesktopDashboardScreen(),
        '/profile/edit': (_) => const ProfileEditPage(),
        '/settings': (_) => SettingsScreen(
          themeMode: _themeMode,
          onThemeChanged: _setThemeMode,
        ),
      },
      builder: (context, child) {
        final actualChild = child ?? const SizedBox.shrink();
        return AuthScope(
          child: WalletScope(
            controller: widget.walletProvider,
            child: actualChild,
          ),
        );
      },
    );
  }
}
