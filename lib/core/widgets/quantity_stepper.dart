import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Qty Stepper sesuai PRD Section 16:
/// Tombol − dan + berukuran 40 dp dengan angka di tengah;
/// Qty 1 lalu − memunculkan ikon hapus.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact ? 34.0 : 40.0;
    final isAtOne = quantity <= 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tombol minus / hapus
          _StepButton(
            icon: isAtOne ? Icons.delete_outline_rounded : Icons.remove_rounded,
            iconColor: isAtOne ? AppColors.error : AppColors.textPrimary,
            size: buttonSize,
            onTap: onDecrement,
            tooltip: isAtOne ? 'Hapus item' : 'Kurangi',
          ),
          SizedBox(
            width: compact ? 32 : 40,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTypography.price(
                fontSize: compact ? 14 : 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Tombol tambah
          _StepButton(
            icon: Icons.add_rounded,
            size: buttonSize,
            onTap: onIncrement,
            filled: true,
            tooltip: 'Tambah',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.iconColor,
    this.filled = false,
    this.tooltip,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool filled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: filled ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.52,
            color: filled
                ? Colors.white
                : (iconColor ?? AppColors.textPrimary),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
