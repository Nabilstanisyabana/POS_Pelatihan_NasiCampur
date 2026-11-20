import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Soft card dengan radius 16, border outline 1px dan bayangan sangat tipis (PRD 15)
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor,
    this.borderRadius = 16,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? AppColors.outline,
      width: 1,
    );

    final boxDecoration = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    );

    if (onTap != null) {
      return Container(
        decoration: boxDecoration,
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: boxDecoration,
      padding: padding,
      child: child,
    );
  }
}
