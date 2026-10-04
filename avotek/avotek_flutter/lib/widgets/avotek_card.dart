import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AvotekCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool hasHoverEffect;

  const AvotekCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 14.0,
    this.hasHoverEffect = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppColors.darkCard : AppColors.lightCard);
    final border = borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    final cardWidget = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0x0A0A1628),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          hoverColor: isDark
              ? AppColors.primaryBlue.withValues(alpha: 0.08)
              : AppColors.primaryBlue.withValues(alpha: 0.04),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}
