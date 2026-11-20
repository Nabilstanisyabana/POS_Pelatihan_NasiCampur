import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.light = false,
    this.onDark = false,
    this.subtitle,
  });

  final double size;
  final bool light;
  final bool onDark;
  final String? subtitle;

  bool get _isLight => light || onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F766E),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: size * 0.58,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NusaPOS',
              style: AppTypography.title(
                color: _isLight ? Colors.white : AppColors.textPrimary,
              ).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.44,
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle != null || subtitle == null)
              Text(
                subtitle ?? 'Aplikasi POS Sederhana',
                style: AppTypography.caption(
                  color: _isLight ? Colors.white70 : AppColors.textSecondary,
                ).copyWith(
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
