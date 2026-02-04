import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D23),
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative 3D objects
            Positioned(
              top: 60,
              right: 30,
              child: _buildDecorativeShape(
                size: 100,
                colors: [
                  Colors.blue.shade300.withOpacity(0.3),
                  Colors.purple.shade300.withOpacity(0.3),
                ],
              ),
            ),
            Positioned(
              bottom: 380,
              left: 20,
              child: _buildDecorativeShape(
                size: 90,
                colors: [
                  Colors.grey.shade400.withOpacity(0.2),
                  Colors.blue.shade200.withOpacity(0.2),
                ],
              ),
            ),
            Positioned(
              bottom: 200,
              right: 20,
              child: _buildDecorativeShape(
                size: 100,
                colors: [
                  Colors.purple.shade400.withOpacity(0.3),
                  Colors.pink.shade300.withOpacity(0.3),
                ],
              ),
            ),
            // Main content
            Column(
              children: [
                const Spacer(flex: 2),
                // ATX Logo
                Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.shade400.withOpacity(0.4),
                        Colors.cyan.shade300.withOpacity(0.3),
                        Colors.purple.shade400.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade600,
                            Colors.blue.shade400,
                            Colors.cyan.shade300,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Text(
                        'ATX',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Свобода твоих финансов',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Продолжая дальше вы соглашаетесь с Условиями и\nПолитикой конфиденциальности',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      // Create new wallet button
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
                            backgroundColor: const Color(0xFF5B6FF9),
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
                      // Already have wallet button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3140),
                            foregroundColor: Colors.white,
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
                const SizedBox(height: 50),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeShape({
    required double size,
    required List<Color> colors,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
