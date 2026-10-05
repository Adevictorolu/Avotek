import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Rotating Avotek Logo with dot-dot-dot micro-animation inside a stylish border
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
    // 0.3 second rotation cycle matching 0.3s transition requirement
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldColor = widget.borderColor ?? const Color(0xFFD4AF37);
    final dotColor = widget.dotColor ?? const Color(0xFFE5A93C);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating dashed/dotted border
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: goldColor.withOpacity(0.35),
                          width: 2.0,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Orbiting dot 1
                          Positioned(
                            top: 2,
                            left: widget.size / 2 - 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: dotColor.withOpacity(0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Orbiting dot 2
                          Positioned(
                            bottom: 6,
                            right: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Orbiting dot 3
                          Positioned(
                            bottom: 6,
                            left: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A3FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Center Avotek Icon
              Container(
                width: widget.size * 0.65,
                height: widget.size * 0.65,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141720) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w900,
                      fontSize: widget.size * 0.35,
                      color: goldColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Pulsing Dot-Dot-Dot text indicator
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final step = (_controller.value * 3).floor() % 3;
              final dots = step == 0 ? '· ' : (step == 1 ? '· · ' : '· · ·');
              return Text(
                dots,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: dotColor,
                ),
              );
            },
          ),
          if (widget.showLabel) ...[
            const SizedBox(height: 4),
            Text(
              'Avotek',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
