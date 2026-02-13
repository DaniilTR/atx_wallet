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
    return SizedBox(
      height: 110 + bottomPadding,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 25,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _NavBarClipper(),
              child: Container(
                height: 85 + bottomPadding,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(20, 255, 255, 255),
                ),
              ),
            ),
          ),
          Positioned(
            top: 45,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavIcon(
                  icon: Icons.home_rounded,
                  active: index == 0,
                  onTap: () => onChanged(0),
                  activeColor: Colors.white,
                ),
                _NavIcon(
                  icon: Icons.pie_chart_rounded,
                  active: index == 1,
                  onTap: () => onChanged(1),
                  activeColor: Colors.white,
                ),
                const SizedBox(width: 80),
                _NavIcon(
                  icon: Icons.card_giftcard_rounded,
                  active: index == 2,
                  onTap: () => onChanged(2),
                  activeColor: Colors.white,
                ),
                _NavIcon(
                  icon: Icons.table_rows_rounded,
                  active: index == 3,
                  onTap: () => onChanged(3),
                  activeColor: Colors.white,
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onQrTap,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4D6CFF).withOpacity(.6),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final center = w / 2;

    const notchRadius = 44.0;
    const notchDepth = 16.0;

    path.lineTo(center - notchRadius - 30, 0);

    path.quadraticBezierTo(
      center - notchRadius,
      0,
      center - notchRadius,
      notchDepth,
    );

    path.arcToPoint(
      Offset(center + notchRadius, notchDepth),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    path.quadraticBezierTo(
      center + notchRadius,
      0,
      center + notchRadius + 30,
      0,
    );

    path.lineTo(w, 0);
    path.lineTo(w, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.activeColor,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: active ? activeColor : const Color(0xFFD2D8F6),
        size: 26,
      ),
    );
  }
}
