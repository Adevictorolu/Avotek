import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final bool isPill;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    this.isPill = true,
  });

  factory StatusBadge.success(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      icon: icon ?? Icons.check_circle_outline,
      color: const Color(0xFF059669),
      backgroundColor: const Color(0xFFE7F6EC),
    );
  }

  factory StatusBadge.pending(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      icon: icon ?? Icons.schedule,
      color: const Color(0xFFB7791F),
      backgroundColor: const Color(0xFFFDF4E3),
    );
  }

  factory StatusBadge.failed(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      icon: icon ?? Icons.error_outline,
      color: const Color(0xFFDC2626),
      backgroundColor: const Color(0xFFFEE2E2),
    );
  }

  factory StatusBadge.academic(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      icon: icon ?? Icons.school_outlined,
      color: const Color(0xFF0070F3),
      backgroundColor: const Color(0xFFEFF6FF),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryBlue;
    final effectiveBg = backgroundColor ?? effectiveColor.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(isPill ? 999 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: effectiveColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
