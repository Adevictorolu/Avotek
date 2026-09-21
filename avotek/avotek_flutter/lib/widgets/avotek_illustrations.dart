import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Vector Illustration 1: Instant VTU & Data Bundles
class AvotekVtuIllustration extends StatelessWidget {
  final double size;
  const AvotekVtuIllustration({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _VtuIllustrationPainter(),
    );
  }
}

class _VtuIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    // Outer subtle ambient glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryCyan.withValues(alpha: 0.25),
          AppColors.primaryBlue.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.48));
    canvas.drawCircle(center, w * 0.48, glowPaint);

    // Decorative signal rings
    final ringPaint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, w * 0.38, ringPaint);

    final innerRingPaint = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, w * 0.26, innerRingPaint);

    // Smartphone device frame
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w * 0.38, height: h * 0.62),
      const Radius.circular(20),
    );

    final phonePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(phoneRect.outerRect);
    canvas.drawRRect(phoneRect, phonePaint);

    final phoneBorder = Paint()
      ..color = AppColors.primaryCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(phoneRect, phoneBorder);

    // Phone screen inside
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w * 0.32, height: h * 0.52),
      const Radius.circular(12),
    );
    final screenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryBlue.withValues(alpha: 0.4),
          const Color(0xFF0A0E17),
        ],
      ).createShader(screenRect.outerRect);
    canvas.drawRRect(screenRect, screenPaint);

    // Lightning Bolt in center of phone
    final boltPath = Path();
    boltPath.moveTo(center.dx + w * 0.02, center.dy - h * 0.12);
    boltPath.lineTo(center.dx - w * 0.05, center.dy + h * 0.01);
    boltPath.lineTo(center.dx + w * 0.01, center.dy + h * 0.01);
    boltPath.lineTo(center.dx - w * 0.02, center.dy + h * 0.12);
    boltPath.lineTo(center.dx + w * 0.06, center.dy - h * 0.01);
    boltPath.lineTo(center.dx - w * 0.00, center.dy - h * 0.01);
    boltPath.close();

    final boltPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, AppColors.primaryCyan],
      ).createShader(boltPath.getBounds());
    canvas.drawPath(boltPath, boltPaint);

    // Orbiting network nodes
    final nodePoints = [
      Offset(center.dx - w * 0.32, center.dy - h * 0.2), // Top-left
      Offset(center.dx + w * 0.32, center.dy - h * 0.18), // Top-right
      Offset(center.dx - w * 0.28, center.dy + h * 0.22), // Bottom-left
      Offset(center.dx + w * 0.28, center.dy + h * 0.24), // Bottom-right
    ];

    final nodeColors = [
      AppColors.mtnYellow,
      AppColors.airtelRed,
      AppColors.gloGreen,
      AppColors.primaryCyan,
    ];

    for (int i = 0; i < nodePoints.length; i++) {
      final pt = nodePoints[i];
      // Dashed connection line to phone
      final linePaint = Paint()
        ..color = nodeColors[i].withValues(alpha: 0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pt, center, linePaint);

      // Node circle
      final nodeCircle = Paint()..color = nodeColors[i];
      canvas.drawCircle(pt, 9, nodeCircle);

      final nodeWhite = Paint()..color = Colors.white;
      canvas.drawCircle(pt, 4, nodeWhite);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vector Illustration 2: Academic Exam PINs & Educational Services
class AvotekAcademicIllustration extends StatelessWidget {
  final double size;
  const AvotekAcademicIllustration({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AcademicIllustrationPainter(),
    );
  }
}

class _AcademicIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    // Background ambient aura
    final aura = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.2),
          const Color(0xFF0284C7).withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.46));
    canvas.drawCircle(center, w * 0.46, aura);

    // Graduation Cap Top (Diamond)
    final capPath = Path();
    capPath.moveTo(center.dx, center.dy - h * 0.22); // Top apex
    capPath.lineTo(center.dx + w * 0.34, center.dy - h * 0.10); // Right
    capPath.lineTo(center.dx, center.dy + h * 0.02); // Bottom apex
    capPath.lineTo(center.dx - w * 0.34, center.dy - h * 0.10); // Left
    capPath.close();

    final capPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00A3FF), Color(0xFF005299)],
      ).createShader(capPath.getBounds());
    canvas.drawPath(capPath, capPaint);

    final capBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(capPath, capBorder);

    // Skull cap base
    final skullPath = Path();
    skullPath.moveTo(center.dx - w * 0.18, center.dy - h * 0.04);
    skullPath.quadraticBezierTo(
      center.dx,
      center.dy + h * 0.12,
      center.dx + w * 0.18,
      center.dy - h * 0.04,
    );
    skullPath.close();
    final skullPaint = Paint()..color = const Color(0xFF003866);
    canvas.drawPath(skullPath, skullPaint);

    // Tassel ribbon
    final tasselPath = Path();
    tasselPath.moveTo(center.dx, center.dy - h * 0.10);
    tasselPath.quadraticBezierTo(
      center.dx + w * 0.30,
      center.dy - h * 0.05,
      center.dx + w * 0.30,
      center.dy + h * 0.08,
    );
    final tasselPaint = Paint()
      ..color = const Color(0xFFFFD700) // Gold tassel
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(tasselPath, tasselPaint);

    // Golden tassel bob
    canvas.drawCircle(Offset(center.dx + w * 0.30, center.dy + h * 0.09), 5, Paint()..color = const Color(0xFFFFD700));

    // Certificate / Result Card at bottom
    final certRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.22), width: w * 0.55, height: h * 0.26),
      const Radius.circular(10),
    );
    final certPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRRect(certRect, certPaint);

    final certBorder = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(certRect, certBorder);

    // Certificate lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - w * 0.2, center.dy + h * 0.16),
      Offset(center.dx + w * 0.12, center.dy + h * 0.16),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - w * 0.2, center.dy + h * 0.22),
      Offset(center.dx + w * 0.18, center.dy + h * 0.22),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - w * 0.2, center.dy + h * 0.28),
      Offset(center.dx + w * 0.05, center.dy + h * 0.28),
      linePaint,
    );

    // Green verification checkmark badge
    canvas.drawCircle(Offset(center.dx + w * 0.20, center.dy + h * 0.28), 8, Paint()..color = AppColors.success);
    final checkPath = Path();
    checkPath.moveTo(center.dx + w * 0.17, center.dy + h * 0.28);
    checkPath.lineTo(center.dx + w * 0.195, center.dy + h * 0.30);
    checkPath.lineTo(center.dx + w * 0.23, center.dy + h * 0.26);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vector Illustration 3: Leveraging Technology in Education
class AvotekFintechIllustration extends StatelessWidget {
  final double size;
  const AvotekFintechIllustration({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FintechIllustrationPainter(),
    );
  }
}

class _FintechIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    // Glowing background circuit grid
    final gridPaint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, w * 0.44, gridPaint);
    canvas.drawCircle(center, w * 0.32, gridPaint);

    // Shield outline
    final shieldPath = Path();
    shieldPath.moveTo(center.dx, center.dy - h * 0.32);
    shieldPath.lineTo(center.dx + w * 0.30, center.dy - h * 0.18);
    shieldPath.lineTo(center.dx + w * 0.30, center.dy + h * 0.05);
    shieldPath.quadraticBezierTo(
      center.dx + w * 0.24,
      center.dy + h * 0.28,
      center.dx,
      center.dy + h * 0.36,
    );
    shieldPath.quadraticBezierTo(
      center.dx - w * 0.24,
      center.dy + h * 0.28,
      center.dx - w * 0.30,
      center.dy + h * 0.05,
    );
    shieldPath.lineTo(center.dx - w * 0.30, center.dy - h * 0.18);
    shieldPath.close();

    final shieldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF0A0E17)],
      ).createShader(shieldPath.getBounds());
    canvas.drawPath(shieldPath, shieldPaint);

    final shieldBorder = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryCyan, AppColors.primaryBlue],
      ).createShader(shieldPath.getBounds())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(shieldPath, shieldBorder);

    // Graduation Cap + Digital Lock inside shield
    // 1. Digital Lock Body
    final lockRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.06), width: w * 0.24, height: h * 0.20),
      const Radius.circular(8),
    );
    canvas.drawRRect(lockRect, Paint()..color = AppColors.primaryCyan);

    // 2. Lock Shackle
    final shacklePath = Path();
    shacklePath.moveTo(center.dx - w * 0.08, center.dy - h * 0.04);
    shacklePath.quadraticBezierTo(
      center.dx - w * 0.08,
      center.dy - h * 0.14,
      center.dx,
      center.dy - h * 0.14,
    );
    shacklePath.quadraticBezierTo(
      center.dx + w * 0.08,
      center.dy - h * 0.14,
      center.dx + w * 0.08,
      center.dy - h * 0.04,
    );
    final shacklePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawPath(shacklePath, shacklePaint);

    // 3. Keyhole
    canvas.drawCircle(Offset(center.dx, center.dy + h * 0.04), 4, Paint()..color = const Color(0xFF0A0E17));
    final keyholeBottom = Path()
      ..moveTo(center.dx - 2, center.dy + h * 0.04)
      ..lineTo(center.dx - 3, center.dy + h * 0.10)
      ..lineTo(center.dx + 3, center.dy + h * 0.10)
      ..lineTo(center.dx + 2, center.dy + h * 0.04)
      ..close();
    canvas.drawPath(keyholeBottom, Paint()..color = const Color(0xFF0A0E17));

    // Stars & tech nodes
    canvas.drawCircle(Offset(center.dx - w * 0.35, center.dy), 4, Paint()..color = AppColors.primaryCyan);
    canvas.drawCircle(Offset(center.dx + w * 0.35, center.dy - h * 0.1), 5, Paint()..color = const Color(0xFFFFD700));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vector Illustration 4: Auth Hero Banner
class AvotekAuthHeroIllustration extends StatelessWidget {
  final double width;
  final double height;
  const AvotekAuthHeroIllustration({super.key, this.width = 360, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _AuthHeroPainter(),
    );
  }
}

class _AuthHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Glowing subtle circuit background
    final bgGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryCyan.withValues(alpha: 0.18),
          AppColors.primaryBlue.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(center: center, width: w * 0.9, height: h * 0.9));
    canvas.drawOval(Rect.fromCenter(center: center, width: w * 0.9, height: h * 0.9), bgGlow);

    // Circuit track lines
    final trackPaint = Paint()
      ..color = AppColors.primaryCyan.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Left circuit trace
    final leftTrace = Path()
      ..moveTo(w * 0.05, h * 0.5)
      ..lineTo(w * 0.25, h * 0.5)
      ..lineTo(w * 0.35, h * 0.3)
      ..lineTo(w * 0.42, h * 0.3);
    canvas.drawPath(leftTrace, trackPaint);
    canvas.drawCircle(Offset(w * 0.05, h * 0.5), 3, Paint()..color = AppColors.primaryCyan);

    // Right circuit trace
    final rightTrace = Path()
      ..moveTo(w * 0.95, h * 0.5)
      ..lineTo(w * 0.75, h * 0.5)
      ..lineTo(w * 0.65, h * 0.7)
      ..lineTo(w * 0.58, h * 0.7);
    canvas.drawPath(rightTrace, trackPaint);
    canvas.drawCircle(Offset(w * 0.95, h * 0.5), 3, Paint()..color = AppColors.primaryCyan);

    // Center graduation cap + phone silhouette
    final capPath = Path();
    capPath.moveTo(center.dx, center.dy - h * 0.28);
    capPath.lineTo(center.dx + w * 0.14, center.dy - h * 0.12);
    capPath.lineTo(center.dx, center.dy + h * 0.04);
    capPath.lineTo(center.dx - w * 0.14, center.dy - h * 0.12);
    capPath.close();

    final capGrad = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryCyan, AppColors.primaryBlue],
      ).createShader(capPath.getBounds());
    canvas.drawPath(capPath, capGrad);

    // Tassel
    canvas.drawLine(
      Offset(center.dx, center.dy - h * 0.12),
      Offset(center.dx + w * 0.13, center.dy + h * 0.02),
      Paint()
        ..color = const Color(0xFFFFD700)
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(Offset(center.dx + w * 0.13, center.dy + h * 0.03), 3, Paint()..color = const Color(0xFFFFD700));

    // Platform base line
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.26), width: w * 0.34, height: h * 0.12),
      const Radius.circular(6),
    );
    canvas.drawRRect(baseRect, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(
      baseRect,
      Paint()
        ..color = AppColors.primaryCyan.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Brand Icons (Google, Yahoo, Facebook, Phone)
class BrandIcon extends StatelessWidget {
  final String brand; // 'google', 'yahoo', 'facebook', 'phone'
  final double size;

  const BrandIcon({super.key, required this.brand, this.size = 20});

  @override
  Widget build(BuildContext context) {
    switch (brand.toLowerCase()) {
      case 'google':
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _GoogleIconPainter()),
        );
      case 'yahoo':
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF6001D2), // Official Yahoo Purple
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            'Y!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.55,
            ),
          ),
        );
      case 'facebook':
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF1877F2), // Official Facebook Blue
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            'f',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.72,
              fontFamily: 'sans-serif',
            ),
          ),
        );
      case 'phone':
      default:
        return Icon(
          Icons.phone_iphone_rounded,
          size: size,
          color: AppColors.primaryCyan,
        );
    }
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final red = Paint()..color = const Color(0xFFEA4335);
    final blue = Paint()..color = const Color(0xFF4285F4);
    final yellow = Paint()..color = const Color(0xFFFBBC05);
    final green = Paint()..color = const Color(0xFF34A853);

    // Red arc (Top)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 0.5,
      true,
      red,
    );

    // Yellow arc (Left)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 1.25,
      pi * 0.5,
      true,
      yellow,
    );

    // Green arc (Bottom)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.25,
      pi * 0.5,
      true,
      green,
    );

    // Blue arc (Right)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.25,
      pi * 0.5,
      true,
      blue,
    );

    // Inner cutout circle
    canvas.drawCircle(center, radius * 0.55, Paint()..color = Colors.white);

    // Horizontal blue bar
    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - radius * 0.22,
      radius * 0.95,
      radius * 0.44,
    );
    canvas.drawRect(barRect, blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
