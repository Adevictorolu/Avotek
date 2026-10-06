import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AvotekLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool? isDark;
  final bool useAssetImage;
  final bool isLarge;
  final bool hasFrame;
  final double borderRadius;

  const AvotekLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.isDark,
    this.useAssetImage = true,
    this.isLarge = false,
    this.hasFrame = false,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    Widget logoWidget;

    if (useAssetImage) {
      final assetPath = isLarge
          ? (effectiveDark ? 'assets/images/logo_large.png' : 'assets/images/logo_large_light.png')
          : (effectiveDark ? 'assets/images/logo.png' : 'assets/images/logo_light.png');

      logoWidget = Image.asset(
        assetPath,
        height: size,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (context, error, stackTrace) => _buildVectorLogo(effectiveDark),
      );
    } else {
      logoWidget = _buildVectorLogo(effectiveDark);
    }

    if (hasFrame) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: effectiveDark ? const Color(0xFF131B2E) : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: effectiveDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius > 4 ? borderRadius - 2 : 4),
          child: logoWidget,
        ),
      );
    }

    return logoWidget;
  }

  Widget _buildVectorLogo(bool effectiveDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBlue.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.primaryCyan, width: 1.5),
          ),
          child: CustomPaint(
            painter: _AvotekCircuitPainter(isDark: effectiveDark),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'AVO',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: size * 0.52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: effectiveDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                TextSpan(
                  text: 'TEK',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: size * 0.52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
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

/// Dedicated widget to render the authentic AVOTEK brand logo asset with light/dark adaptation
class AvotekBrandAsset extends StatelessWidget {
  final double height;
  final double? width;
  final bool isDark;
  final bool isLarge;
  final bool hasFrame;
  final double borderRadius;

  const AvotekBrandAsset({
    super.key,
    this.height = 36,
    this.width,
    required this.isDark,
    this.isLarge = false,
    this.hasFrame = false,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = isLarge
        ? (isDark ? 'assets/images/logo_large.png' : 'assets/images/logo_large_light.png')
        : (isDark ? 'assets/images/logo.png' : 'assets/images/logo_light.png');

    final imageWidget = Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return AvotekLogo(
          size: height,
          isDark: isDark,
          useAssetImage: false,
          showText: true,
        );
      },
    );

    if (hasFrame) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2E) : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isDark ? const Color(0xFF23304B) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius > 4 ? borderRadius - 2 : 4),
          child: imageWidget,
        ),
      );
    }

    return imageWidget;
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
