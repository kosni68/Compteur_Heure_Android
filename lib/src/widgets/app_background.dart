import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = brightness == Brightness.light
        ? const [
            Color(0xFFF8F1E7),
            Color(0xFFE2F0EE),
          ]
        : const [
            Color(0xFF0F172A),
            Color(0xFF111827),
          ];
    final glowA = brightness == Brightness.light
        ? const Color(0xFFFE6D73)
        : const Color(0xFF64748B);
    final glowB = brightness == Brightness.light
        ? const Color(0xFF3CB371)
        : const Color(0xFF0EA5E9);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -30,
            child: _GlowBlob(
              size: 220,
              color: glowA,
            ),
          ),
          Positioned(
            left: -60,
            bottom: 60,
            child: _GlowBlob(
              size: 180,
              color: glowB,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
