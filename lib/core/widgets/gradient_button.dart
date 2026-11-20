import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tombol sesuai PRD Section 15 & 16:
/// - Primary: latar primary (#0F766E), teks putih, tinggi 52 dp, radius 12 dp
/// - Secondary: outline primary, teks primary
/// - Destructive: latar error (#DC2626)
/// - Disabled: abu-abu + loading spinner
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    this.text,
    this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height = 52.0,
  }) : assert(text != null || label != null, 'Provide either text or label');

  final String? text;
  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final double height;

  String get _buttonText => text ?? label ?? '';

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (loading) {
      child = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            _buttonText,
            style: AppTypography.label(color: Colors.white).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    } else {
      child = Text(
        _buttonText,
        style: AppTypography.label(color: Colors.white).copyWith(
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.outline,
        disabledForegroundColor: AppColors.textSecondary,
        minimumSize: Size(fullWidth ? double.infinity : 0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: child,
    );

    return button;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    this.text,
    this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height = 52.0,
  }) : assert(text != null || label != null, 'Provide either text or label');

  final String? text;
  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  String get _buttonText => text ?? label ?? '';

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            _buttonText,
            style: AppTypography.label(color: AppColors.primary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    } else {
      child = Text(
        _buttonText,
        style: AppTypography.label(color: AppColors.primary).copyWith(
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: Size(fullWidth ? double.infinity : 0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: child,
    );
  }
}

class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    this.text,
    this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height = 52.0,
  }) : assert(text != null || label != null, 'Provide either text or label');

  final String? text;
  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  String get _buttonText => text ?? label ?? '';

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            _buttonText,
            style: AppTypography.label(color: Colors.white).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    } else {
      child = Text(
        _buttonText,
        style: AppTypography.label(color: Colors.white).copyWith(
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        minimumSize: Size(fullWidth ? double.infinity : 0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: child,
    );
  }
}

/// Alias for backwards compatibility
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    this.text,
    this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.gradient,
    this.expand = true,
    this.height = 52.0,
  }) : assert(text != null || label != null, 'Provide either text or label');

  final String? text;
  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Gradient? gradient;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: text ?? label,
      onPressed: onPressed,
      icon: icon,
      loading: loading,
      fullWidth: expand,
      height: height,
    );
  }
}
