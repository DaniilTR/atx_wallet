import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedNeonBackground extends StatefulWidget {
  const AnimatedNeonBackground({super.key});

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
              const _GradientBackdrop(),
              // Плавающие неоновые круги
              ..._buildFloatingBlobs(context, _controller.value),
              // Лёгкий тёмный вуаль, чтобы контент читался
              Container(color: Colors.black.withOpacity(0.15)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingBlobs(BuildContext context, double t) {
    // t идёт [0..1], используем разные фазы/скорости
    final size = MediaQuery.of(context).size;

    Widget blob({
      required double baseX,
      required double baseY,
      required double ampX,
      required double ampY,
      required double phase,
      required double radius,
      required List<Color> colors,
    }) {
      final angle = 2 * math.pi * (t + phase);
      final x = baseX + ampX * math.sin(angle);
      final y = baseY + ampY * math.cos(angle * 0.9);
      return Positioned(
        left: size.width * x - radius,
        top: size.height * y - radius,
        child: _NeonCircle(radius: radius, colors: colors),
      );
    }

    return [
      blob(
        baseX: 0.10,
        baseY: 0.2,
        ampX: 0.06,
        ampY: 0.04,
        phase: 0.25,
        radius: 110,
        colors: [
          const Color(0xFF2CB67D).withOpacity(0.75), // Зеленый неон 
          const Color(0xFFFFD166).withOpacity(0.55), // Желтый неон
        ],
      ),
      blob(
        baseX: 0.90,
        baseY: 0.8,
        ampX: 0.05,
        ampY: 0.05,
        phase: 0.75,
        radius: 120,
        colors: [
          const Color(0xFF4B0082).withOpacity(0.7), // феолетово темный неон
          const Color(0xFF8B00FF).withOpacity(0.5), // феолетово розовый неон
        ],
      ),
    ];
  }
}

class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1020),
            Color(0xFF0D1326),
            Color(0xFF0A0F1C),
          ],
        ),
      ),
    );
  }
}

class _NeonCircle extends StatelessWidget {
  const _NeonCircle({required this.radius, required this.colors});
  final double radius;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colors.first,
              colors.last.withOpacity(0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              // Светящееся свечение
              BoxShadow(
                color: colors.first.withOpacity(0.45),
                blurRadius: radius * 0.9,
                spreadRadius: radius * 0.15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
