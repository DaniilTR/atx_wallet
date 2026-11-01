import 'dart:ui';

import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    required this.onQrTap,
    required this.isDark,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onQrTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final activeColor = isDark ? Colors.white : const Color(0xFF172033);
    final inactiveColor = isDark
        ? const Color(0xFF9EA8C0)
        : const Color(0xFF64748B);
    return SizedBox(
      height: 96 + bottomPadding,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 8, 14, bottomPadding + 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.09)
                        : Colors.white.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.24 : 0.10,
                        ),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Главная',
                          active: index == 0,
                          onTap: () => onChanged(0),
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.pie_chart_rounded,
                          label: 'Рынок',
                          active: index == 1,
                          onTap: () => onChanged(1),
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                      ),
                      _CenterAction(
                        onTap: onQrTap,
                        isDark: isDark,
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.local_activity_rounded,
                          label: 'Награды',
                          active: index == 2,
                          onTap: () => onChanged(2),
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          icon: Icons.history_rounded,
                          label: 'История',
                          active: index == 3,
                          onTap: () => onChanged(3),
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({required this.onTap, required this.isDark});

  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 58,
          height: 58,
          child: CustomPaint(
            painter: _CenterActionGlowPainter(),
            child: Center(
              child: Image.asset(
                'assets/images/chat-ai.png',
                width: 26,
                height: 26,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterActionGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final borderRadius = size.shortestSide / 2 - 2;

    for (final glow in [
      (radius: borderRadius + 1.5, alpha: 0.16, width: 2.0),
      (radius: borderRadius + 3.0, alpha: 0.08, width: 2.0),
    ]) {
      canvas.drawCircle(
        center,
        glow.radius,
        Paint()
          ..color = Colors.white.withValues(alpha: glow.alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = glow.width,
      );
    }

    canvas.drawCircle(
      center,
      borderRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _CenterActionGlowPainter oldDelegate) => false;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
