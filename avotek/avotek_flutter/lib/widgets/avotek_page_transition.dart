import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'avotek_logo.dart';

/// Rotating Avotek Logo with orbiting micro-animation inside a stylish border
class AvotekRotatingLogoDotsLoader extends StatefulWidget {
  final double size;
  final Color? borderColor;
  final Color? dotColor;
  final bool showLabel;

  const AvotekRotatingLogoDotsLoader({
    super.key,
    this.size = 56,
    this.borderColor,
    this.dotColor,
    this.showLabel = false,
  });

  @override
  State<AvotekRotatingLogoDotsLoader> createState() => _AvotekRotatingLogoDotsLoaderState();
}

class _AvotekRotatingLogoDotsLoaderState extends State<AvotekRotatingLogoDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 0.6 second rotation cycle matching transition requirement
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cyanColor = widget.borderColor ?? const Color(0xFF00D2FF);
    final blueColor = widget.dotColor ?? const Color(0xFF0052FF);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating circular progress ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _TransitionRingPainter(
                    strokeWidth: 3.2,
                    color: cyanColor,
                    secondaryColor: blueColor,
                  ),
                ),
              );
            },
          ),

          // Center Authentic Framed Avotek Logo
          AvotekLogo(
            size: widget.size * 0.56,
            hasFrame: true,
            showText: false,
            borderRadius: widget.size * 0.18,
          ),
        ],
      ),
    );
  }
}

class _TransitionRingPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final Color secondaryColor;

  _TransitionRingPainter({
    required this.strokeWidth,
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.3)
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
  bool shouldRepaint(covariant _TransitionRingPainter oldDelegate) => false;
}

/// Fast 0.3s (300ms) Page Transition with seamless cubic ease
class AvotekFastTransitionPage<T> extends CustomTransitionPage<T> {
  AvotekFastTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Helper to wrap any widget in a fast 0.3s transition page
CustomTransitionPage<void> buildAvotekTransitionPage(BuildContext context, GoRouterState state, Widget child) {
  return AvotekFastTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}
