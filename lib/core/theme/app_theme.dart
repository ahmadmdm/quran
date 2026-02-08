import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhan/adhan.dart';

class AppColors {
  // Dark Theme Colors
  static const Color background = Color(0xFF0B1020);
  static const Color primary = Color(0xFF1E2A5E);
  static const Color accent = Color(0xFFC9A24D); // Gold
  static const Color text = Color(0xFFF1F1F1);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color surface = Color(0xFF151C2F);
  static const Color card = Color(0xFF1A1F38);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A2E);

  static final Color glow = const Color(0xFFC9A24D).withValues(alpha: 0.3);
  static final Color glass = const Color(0xFF1E2A5E).withValues(alpha: 0.2);
}

class AppTheme {
  static LinearGradient getPrayerGradient(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        );
      case Prayer.sunrise:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6F00), Color(0xFFFF8F00), Color(0xFFFFA000)],
        );
      case Prayer.dhuhr:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0277BD), Color(0xFF0288D1), Color(0xFF039BE5)],
        );
      case Prayer.asr:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE65100), Color(0xFFEF6C00), Color(0xFFF57C00)],
        );
      case Prayer.maghrib:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFAD1457), Color(0xFFC2185B), Color(0xFFD81B60)],
        );
      case Prayer.isha:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF1565C0)],
        );
      case Prayer.none:
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.background, Color(0xFF0F182E)],
        );
    }
  }

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.cairo().fontFamily,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerColor: Colors.black12,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
        primaryContainer: Color(0xFFE8EAF6),
        onPrimaryContainer: AppColors.primary,
        secondaryContainer: Color(0xFFFFF8E1),
        onSecondaryContainer: Color(0xFF8B6914),
      ),
      textTheme: GoogleFonts.cairoTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.cairo(
          color: AppColors.lightText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.cairo(
          color: AppColors.lightText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.cairo(
          color: AppColors.lightText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.cairo(
          color: AppColors.lightText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.cairo(color: AppColors.lightText, fontSize: 16),
        bodyMedium: GoogleFonts.cairo(
          color: AppColors.lightText.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.cairo(
          color: AppColors.lightText.withValues(alpha: 0.6),
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.cairo(
          color: AppColors.lightText,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: GoogleFonts.cairo(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.cairo().fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerColor: AppColors.glassBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        primaryContainer: Color(0xFF1E2A5E),
        onPrimaryContainer: AppColors.text,
        secondaryContainer: Color(0xFF3D3219),
        onSecondaryContainer: AppColors.accent,
      ),
      textTheme: GoogleFonts.cairoTextTheme(baseTextTheme)
          .apply(bodyColor: AppColors.text, displayColor: AppColors.text)
          .copyWith(
            displayLarge: GoogleFonts.cairo(
              color: AppColors.text,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            displayMedium: GoogleFonts.cairo(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: GoogleFonts.cairo(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            titleMedium: GoogleFonts.cairo(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: GoogleFonts.cairo(color: AppColors.text, fontSize: 16),
            bodyMedium: GoogleFonts.cairo(
              color: AppColors.text.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            bodySmall: GoogleFonts.cairo(
              color: AppColors.text.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            labelLarge: GoogleFonts.cairo(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
      iconTheme: const IconThemeData(color: AppColors.accent),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.accent,
        contentTextStyle: GoogleFonts.cairo(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
