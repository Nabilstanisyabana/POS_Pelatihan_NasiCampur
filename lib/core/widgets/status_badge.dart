import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../theme/app_theme.dart';

/// Badge Status Pembayaran sesuai PRD Section 16:
/// - Menunggu (warning, ikon jam)
/// - Berhasil (success, ikon centang)
/// - Gagal (error, ikon silang)
/// - Kedaluwarsa (error, ikon jam/timer)
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final PaymentStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, bg) = switch (status) {
      PaymentStatus.paid => (
        'Berhasil',
        Icons.check_circle_rounded,
        AppColors.success,
        AppColors.successSoft,
      ),
      PaymentStatus.pending => (
        'Menunggu',
        Icons.schedule_rounded,
        AppColors.warning,
        AppColors.warningSoft,
      ),
      PaymentStatus.failed => (
        'Gagal',
        Icons.cancel_rounded,
        AppColors.error,
        AppColors.errorSoft,
      ),
      PaymentStatus.expired => (
        'Kedaluwarsa',
        Icons.timer_off_rounded,
        AppColors.error,
        AppColors.errorSoft,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999), // Pil radius per PRD
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
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
