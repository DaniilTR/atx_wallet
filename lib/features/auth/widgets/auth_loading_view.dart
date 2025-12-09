import 'package:flutter/material.dart';

import 'animated_neon_background.dart';

class AuthLoadingView extends StatelessWidget {
  const AuthLoadingView({super.key, this.message = 'Проверяем вход...'})
    : assert(message.length > 1, 'Message should not be empty');

  final String message;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Colors.white70,
      fontWeight: FontWeight.w600,
    );
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedNeonBackground(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 52,
                  width: 52,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                Text(message, textAlign: TextAlign.center, style: textStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
