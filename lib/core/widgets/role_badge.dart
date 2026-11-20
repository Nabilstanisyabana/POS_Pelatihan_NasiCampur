import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../theme/app_theme.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role, this.compact = false});

  final UserRole role;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == UserRole.admin;
    final color = isAdmin ? AppColors.primary : AppColors.accent;
    final bg = isAdmin ? AppColors.primaryContainer : AppColors.accentSoft;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings_rounded : Icons.point_of_sale_rounded,
            size: compact ? 12 : 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            role.label,
            style: AppTypography.caption(color: color).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
