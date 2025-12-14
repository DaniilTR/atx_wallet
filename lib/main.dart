import 'dart:async';
import 'package:flutter/material.dart';

import 'services/auth_scope.dart';
import 'services/config.dart';
import 'features/settings/settings_screen.dart';
import 'services/platform.dart';
import 'features/desktop/pairing_screen.dart';
import 'features/desktop/dashboard_screen.dart';
import 'features/mobile/pair_connect_screen.dart';
import 'features/market/market_list_screen.dart';
import 'features/market/market_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/home/home_page.dart';
import 'providers/wallet_provider.dart';
import 'providers/wallet_scope.dart';

Future<void> main() async {
  // Global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Run initialization and app inside the same zone to avoid "Zone mismatch" warnings
    runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await ApiConfig.init();
    final walletProvider = WalletProvider(devEnabled: kEnableDevWalletStorage);
    try {
      await walletProvider.init();
    } catch (_) {}
    runApp(AtxWalletApp(walletProvider: walletProvider));
  }, (Object error, StackTrace stack) {
    // ignore: avoid_print
    print('Uncaught error: $error');
    // ignore: avoid_print
    print(stack);
  });
}

class AtxWalletApp extends StatelessWidget {
  const AtxWalletApp({required this.walletProvider, super.key});

  final WalletProvider walletProvider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7A5AF8),
      brightness: Brightness.dark,
    );

    final initialRoute = isDesktop ? '/desktop/pair' : kInitialRoute;
    // Debug: log platform and chosen initial route to help diagnose startup routing
    // (Remove or guard this in production)
    // ignore: avoid_print
    print('AtxWalletApp starting — isDesktop=$isDesktop initialRoute=$initialRoute');

    return MaterialApp(
      title: 'ATX Wallet',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: colorScheme,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF141826),
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
            borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A2030),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/mobile/pair': (_) => const MobilePairConnectScreen(),
        '/desktop/pair': (_) => const DesktopPairingScreen(),
        '/desktop/dashboard': (_) => const DesktopDashboardScreen(),
        '/market': (_) => const MarketListScreen(),
        '/market/detail': (_) => const MarketDetailScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
      builder: (context, child) {
        final actualChild = child ?? const SizedBox.shrink();
        return AuthScope(
          child: WalletScope(controller: walletProvider, child: actualChild),
        );
      },
    );
  }
}
