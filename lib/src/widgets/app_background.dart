import 'package:flutter/material.dart';

import '../theme/backgrounds.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    required this.backgroundId,
    this.showGlows = true,
  });

  final Widget child;
  final String backgroundId;
  final bool showGlows;

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
    final useTransparentOverlay = backgroundId != 'none';
    final overlayColors = useTransparentOverlay
        ? [
            colors[0].withOpacity(0.85),
            colors[1].withOpacity(0.85),
          ]
        : colors;
    final glowA = brightness == Brightness.light
        ? const Color(0xFFFE6D73)
        : const Color(0xFF64748B);
    final glowB = brightness == Brightness.light
        ? const Color(0xFF3CB371)
        : const Color(0xFF0EA5E9);

    return Stack(
      children: [
        Positioned.fill(child: BackgroundArt(backgroundId: backgroundId)),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: overlayColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        if (showGlows) ...[
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
        ],
        Positioned.fill(child: child),
      ],
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
