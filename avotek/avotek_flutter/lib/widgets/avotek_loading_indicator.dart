import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import 'avotek_logo.dart';

/// Premium Avotek Branded Loading Indicator featuring the framed Avotek logo
/// encircled by a rotating and pulsing circular progress ring.
class AvotekLoadingIndicator extends StatefulWidget {
  final double logoSize;
  final double strokeWidth;
  final String? message;
  final Color? ringColor;

  const AvotekLoadingIndicator({
    super.key,
    this.logoSize = 42,
    this.strokeWidth = 3.5,
    this.message,
    this.ringColor,
  });

  @override
  State<AvotekLoadingIndicator> createState() => _AvotekLoadingIndicatorState();
}

class _AvotekLoadingIndicatorState extends State<AvotekLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringRadius = widget.logoSize * 0.95;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: ringRadius * 2,
          height: ringRadius * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating gradient track
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: CustomPaint(
                  size: Size(ringRadius * 2, ringRadius * 2),
                  painter: _RingProgressPainter(
                    strokeWidth: widget.strokeWidth,
                    color: widget.ringColor ?? AppColors.electricCyan,
                    secondaryColor: AppColors.primaryBlue,
                  ),
                ),
              ),

              // Framed Avotek Logo in the exact center
              AvotekLogo(
                size: widget.logoSize,
                hasFrame: true,
                showText: false,
                borderRadius: widget.logoSize * 0.35,
              ),
            ],
          ),
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            widget.message!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.metallicLight,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _RingProgressPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final Color secondaryColor;

  _RingProgressPainter({
    required this.strokeWidth,
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Subtle background track
    final trackPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.4)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Active sweep arc
    final sweepGradient = SweepGradient(
      colors: [
        color.withOpacity(0.0),
        secondaryColor,
        color,
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final arcPaint = Paint()
      ..shader = sweepGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      1.6 * math.pi,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter oldDelegate) => false;
}

/// Full screen or overlay loader with blurred backdrop and Avotek logo ring
class AvotekPageLoadingOverlay extends StatelessWidget {
  final String? message;

  const AvotekPageLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBg.withOpacity(0.85),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.darkBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AvotekLoadingIndicator(
            logoSize: 48,
            message: message ?? 'Loading Avotek...',
          ),
        ),
      ),
    );
  }
}
