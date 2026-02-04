import 'package:flutter/material.dart';

class AnimatedNeonBackground extends StatefulWidget {
  const AnimatedNeonBackground({this.isDark = true, super.key});

  final bool isDark;

  @override
  State<AnimatedNeonBackground> createState() => _AnimatedNeonBackgroundState();
}

class _AnimatedNeonBackgroundState extends State<AnimatedNeonBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox.expand(
          child: Stack(
            children: [
              // Градиентный фон как база
              _GradientBackdrop(isDark: widget.isDark),
              // Плавающие неоновые круги
              // Лёгкий тёмный вуаль, чтобы контент читался
              Container(
                color: widget.isDark
                    ? Colors.black.withOpacity(0.15)
                    : Colors.white.withOpacity(0.65),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF14191E), Color(0xFF14191E), Color(0xFF14191E)]
              : const [Color(0xFFF6F9FF), Color(0xFFE0E7F3), Color(0xFFDDE5FF)],
        ),
      ),
    );
  }
}
