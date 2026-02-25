import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        // Dark: radial-gradient(circle at top, #0f172a, #020617) — from the CSS
        // Light: clean slate-white gradient
        gradient: isDark
            ? const RadialGradient(
                center: Alignment(0.0, -1.0), // top center
                radius: 1.6,
                colors: [
                  Color(0xFF172341), // slate-900
                  Color(0xFF081552), // slate-950
                ],
                stops: [0.0, 1.0],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3B88D4), // slate-50
                  Color(0xFF97ACF0), // indigo-50
                ],
              ),
      ),
      child: child,
    );
  }
}
