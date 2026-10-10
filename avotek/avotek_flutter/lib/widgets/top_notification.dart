import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

enum TopNotificationType { error, success, info, warning }

/// Custom top-popping notification banner with a countdown circular progress indicator,
/// manual dismiss button, and smooth slide animation.
class TopNotification {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showError(
    BuildContext context,
    String message, {
    String title = 'Notice',
    Duration duration = const Duration(seconds: 5),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: TopNotificationType.error,
      duration: duration,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'Success',
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: TopNotificationType.success,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String title = 'Information',
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: TopNotificationType.info,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String title = 'Warning',
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: TopNotificationType.warning,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    TopNotificationType type = TopNotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    dismiss();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _currentEntry = OverlayEntry(
      builder: (ctx) => _TopNotificationWidget(
        message: message,
        title: title,
        type: type,
        duration: duration,
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_currentEntry!);
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final String? title;
  final TopNotificationType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    this.title,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _animController.forward();

    // Auto dismiss countdown
    Future.delayed(widget.duration, () {
      if (mounted) {
        _handleDismiss();
      }
    });
  }

  void _handleDismiss() async {
    if (!mounted) return;
    await _animController.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _accentColor() {
    switch (widget.type) {
      case TopNotificationType.error:
        return const Color(0xFFEF4444);
      case TopNotificationType.success:
        return const Color(0xFF10B981);
      case TopNotificationType.warning:
        return const Color(0xFFF59E0B);
      case TopNotificationType.info:
        return AppColors.primaryBlue;
    }
  }

  IconData _iconData() {
    switch (widget.type) {
      case TopNotificationType.error:
        return Icons.error_outline_rounded;
      case TopNotificationType.success:
        return Icons.check_circle_outline_rounded;
      case TopNotificationType.warning:
        return Icons.warning_amber_rounded;
      case TopNotificationType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentColor();

    return Positioned(
      top: media.padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.up,
                  onDismissed: (_) => widget.onDismiss(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: accent.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Icon with pulsing halo
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconData(), color: accent, size: 22),
                        ),
                        const SizedBox(width: 14),

                        // Title & Clean Message
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.title != null && widget.title!.isNotEmpty)
                                Text(
                                  widget.title!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              Text(
                                widget.message,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Animated Circular Progress Ring with Close X
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 1.0, end: 0.0),
                                duration: widget.duration,
                                builder: (context, value, _) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 2.2,
                                    backgroundColor: accent.withValues(alpha: 0.15),
                                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                                  );
                                },
                              ),
                            ),
                            InkWell(
                              onTap: _handleDismiss,
                              borderRadius: BorderRadius.circular(15),
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
