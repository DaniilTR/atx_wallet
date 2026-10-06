import 'package:flutter/material.dart';

import '../../services/auth_scope.dart';
import 'widgets/animated_neon_background.dart';
import 'widgets/glass_card.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = AuthScope.of(context);
      final hasUsers = await auth.hasAnyUsers();
      if (!mounted) return;
      if (hasUsers) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : const Color(0xFF172033);
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.58)
        : const Color(0xFF64748B);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedNeonBackground(isDark: isDark),
            // Decorative 3D objects
            Positioned(
              top: 60,
              right: 30,
              child: Image.asset(
                'assets/images/3d_object_1.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: 380,
              left: 20,
              child: Image.asset(
                'assets/images/3d_object_2.png',
                width: 100,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: 200,
              right: 20,
              child: Image.asset(
                'assets/images/3d_object_3.png',
                width: 110,
                height: 110,
                fit: BoxFit.contain,
              ),
            ),
            // Main content
            Column(
              children: [
                const Spacer(flex: 2),
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Image.asset(
                    'assets/images/atx_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Свобода твоих финансов',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      height: 1.3,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Продолжая дальше вы соглашаетесь с Условиями и\nПолитикой конфиденциальности',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedColor,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    borderRadius: 26,
                    child: Column(
                      children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/register',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C6BFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Создать новый кошелек',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.06),
                            foregroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'У меня уже есть кошелек',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
