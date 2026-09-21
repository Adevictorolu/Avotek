import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AvotekLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;

  const AvotekLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _AvotekCircuitPainter(isDark: isDark),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'AVO',
                  style: TextStyle(
                    fontSize: size * 0.48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                TextSpan(
                  text: 'TEK',
                  style: TextStyle(
                    fontSize: size * 0.48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppColors.primaryCyan,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AvotekCircuitPainter extends CustomPainter {
  final bool isDark;
  _AvotekCircuitPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;

    final cyanPaint = Paint()
      ..color = AppColors.primaryCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;

    final greyPaint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;

    final dotCyanPaint = Paint()
      ..color = AppColors.primaryCyan
      ..style = PaintingStyle.fill;

    final dotGreyPaint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    // Draw Left Arc (Cyan)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.6,
      pi * 0.8,
      false,
      cyanPaint,
    );

    // Draw Right/Bottom Arc (Grey)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.4,
      pi * 0.8,
      false,
      greyPaint,
    );

    // Radiating Circuit lines from Left Arc (Cyan)
    final anglesCyan = [pi * 0.7, pi * 0.9, pi * 1.1, pi * 1.3];
    for (final a in anglesCyan) {
      final p1 = Offset(center.dx + radius * cos(a), center.dy + radius * sin(a));
      final p2 = Offset(center.dx + (radius + size.width * 0.14) * cos(a), center.dy + (radius + size.width * 0.14) * sin(a));
      canvas.drawLine(p1, p2, cyanPaint);
      canvas.drawCircle(p2, size.width * 0.04, dotCyanPaint);
    }

    // Radiating Circuit lines from Right Arc (Grey)
    final anglesGrey = [-pi * 0.3, -pi * 0.1, pi * 0.1, pi * 0.3];
    for (final a in anglesGrey) {
      final p1 = Offset(center.dx + radius * cos(a), center.dy + radius * sin(a));
      final p2 = Offset(center.dx + (radius + size.width * 0.14) * cos(a), center.dy + (radius + size.width * 0.14) * sin(a));
      canvas.drawLine(p1, p2, greyPaint);
      canvas.drawCircle(p2, size.width * 0.04, dotGreyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
