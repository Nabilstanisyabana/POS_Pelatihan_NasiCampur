import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna PRD & Design System: Bernuansa teal segar, bersih, dan aman.
class AppColors {
  AppColors._();

  // Design System Tokens (Section 13)
  static const Color primary = Color(0xFF0F766E);          // Teal 700 - Tombol utama, AppBar aktif, ikon aktif
  static const Color primaryContainer = Color(0xFFCCFBF1); // Teal 100 - Chip terpilih, latar highlight
  static const Color onPrimary = Color(0xFFFFFFFF);         // Teks di atas primary
  static const Color accent = Color(0xFFF59E0B);            // Amber 500 - Badge, penanda keranjang, sorotan kecil
  static const Color background = Color(0xFFF8FAFC);        // Slate 50 - Latar halaman
  static const Color surface = Color(0xFFFFFFFF);           // Putih - Kartu, bottom sheet, form
  static const Color outline = Color(0xFFE2E8F0);           // Slate 200 - Border, divider
  static const Color textPrimary = Color(0xFF0F172A);       // Slate 900 - Teks utama
  static const Color textSecondary = Color(0xFF64748B);     // Slate 500 - Teks pendukung, placeholder
  static const Color success = Color(0xFF16A34A);           // Green 600 - Pembayaran berhasil, status Tersedia
  static const Color warning = Color(0xFFD97706);           // Amber 600 - Menunggu pembayaran
  static const Color error = Color(0xFFDC2626);             // Red 600 - Gagal, tombol hapus, validasi

  // Soft tones for backgrounds & badges
  static const Color primarySoft = Color(0xFFCCFBF1);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color accentSoft = Color(0xFFFEF3C7);

  // Backward-compatible aliases
  static const Color ink = textPrimary;
  static const Color inkSoft = Color(0xFF334155);
  static const Color muted = textSecondary;
  static const Color border = outline;
  static const Color danger = error;
  static const Color dangerSoft = errorSoft;
  static const Color mint = success;
  static const Color mintSoft = successSoft;
  static const Color amber = warning;
  static const Color amberSoft = warningSoft;
  static const Color coral = accent;
  static const Color coralSoft = accentSoft;
  static const Color primaryDeep = Color(0xFF115E59);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF134E4A), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Tipografi PRD & Design System (Section 14):
/// Font Heading: Plus Jakarta Sans
/// Font Body & Angka: Inter
class AppTypography {
  AppTypography._();

  static TextStyle display({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.8,
      );

  static TextStyle heading1({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle heading2({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle title({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyL({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyM({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle label({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle caption({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle price({Color color = AppColors.textPrimary, double fontSize = 16}) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        height: 24 / 16,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.outline,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: AppTypography.display(),
        headlineLarge: AppTypography.heading1(),
        headlineMedium: AppTypography.heading2(),
        titleMedium: AppTypography.title(),
        bodyLarge: AppTypography.bodyL(),
        bodyMedium: AppTypography.bodyM(),
        labelLarge: AppTypography.label(),
        bodySmall: AppTypography.caption(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.heading2(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTypography.bodyM(color: AppColors.textSecondary),
        labelStyle: AppTypography.label(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: AppTypography.caption(color: AppColors.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.label(color: AppColors.onPrimary).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.label(color: AppColors.onPrimary).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.label(color: AppColors.primary).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.label(color: AppColors.primary).copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryContainer,
        labelStyle: AppTypography.label(color: AppColors.textSecondary),
        secondaryLabelStyle: AppTypography.label(color: AppColors.primary).copyWith(
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: AppTypography.heading2(),
        contentTextStyle: AppTypography.bodyM(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTypography.bodyM(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryContainer,
        height: 68,
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.caption(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
