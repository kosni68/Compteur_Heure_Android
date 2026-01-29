import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

const String kDefaultBackgroundId = 'none';

const List<String> kBackgroundIds = [
  'none',
  'aurora',
  'dunes',
  'paper',
];

String backgroundLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'aurora':
      return l10n.backgroundAurora;
    case 'dunes':
      return l10n.backgroundDunes;
    case 'paper':
      return l10n.backgroundPaper;
    case 'none':
    default:
      return l10n.backgroundNone;
  }
}

class BackgroundArt extends StatelessWidget {
  const BackgroundArt({super.key, required this.backgroundId});

  final String backgroundId;

  @override
  Widget build(BuildContext context) {
    switch (backgroundId) {
      case 'aurora':
        return const _AuroraArt();
      case 'dunes':
        return const _DunesArt();
      case 'paper':
        return const _PaperArt();
      case 'none':
      default:
        return const SizedBox.shrink();
    }
  }
}

class _AuroraArt extends StatelessWidget {
  const _AuroraArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9AD0F5),
            Color(0xFFE6C6F7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _SoftBlob(
              size: 280,
              color: Color(0xFF7BE495),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -90,
            child: _SoftBlob(
              size: 320,
              color: Color(0xFFFFB199),
            ),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: _SoftBlob(
              size: 200,
              color: Color(0xFF89C2FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _DunesArt extends StatelessWidget {
  const _DunesArt();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DunesPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _DunesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFF9D976),
          Color(0xFFF39F86),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, sky);

    final dune1 = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.55,
        size.width * 0.55,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.7,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final dune2 = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.72,
        size.width * 0.65,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.83,
        size.width,
        size.height * 0.8,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final dunePaint1 = Paint()..color = const Color(0xFFEAC48F);
    final dunePaint2 = Paint()..color = const Color(0xFFD9A46F);
    canvas.drawPath(dune1, dunePaint1);
    canvas.drawPath(dune2, dunePaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaperArt extends StatelessWidget {
  const _PaperArt();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaperPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFF5F1E8),
          Color(0xFFEAE3D9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, base);

    final dotPaint = Paint()..color = const Color(0xFFB7AEA2).withOpacity(0.2);
    const spacing = 24.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x + 6, y + 6), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.55),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}
