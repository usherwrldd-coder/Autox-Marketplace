import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color goldPrimary   = Color(0xFFFF8C00);
  static const Color goldLight     = Color(0xFFFFB347);
  static const Color goldDark      = Color(0xFFCC6600);
  static const Color bgDark        = Color(0xFF080C14);
  static const Color bgCard        = Color(0xFF0D1420);
  static const Color bgCardHover   = Color(0xFF111C30);
  static const Color borderColor   = Color(0x12FFFFFF);
  static const Color borderHover   = Color(0x66FF8C00);
  static const Color textPrimary   = Color(0xFFF0F4FF);
  static const Color textMuted     = Color(0xFF8896B0);
  static const Color textDim       = Color(0xFF4A5568);
  static const Color colorGreen    = Color(0xFF00E676);
  static const Color colorRed      = Color(0xFFFF3B3B);
  static const Color colorBlue     = Color(0xFF00B4FF);
  static const Color colorPurple   = Color(0xFF9C6FFF);

  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor:            goldPrimary,
      colorScheme: const ColorScheme.dark(
        primary:    goldPrimary,
        secondary:  goldLight,
        surface:    bgCard,
        background: bgDark,
        error:      colorRed,
        onPrimary:  Colors.black,
        onSecondary: Colors.black,
        onSurface:  textPrimary,
        onBackground: textPrimary,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge:  const TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 57),
        displayMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 45),
        displaySmall:  const TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 36),
        headlineLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 32),
        headlineMedium:const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 28),
        headlineSmall: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 24),
        titleLarge:    const TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
        titleMedium:   const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall:    const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge:     const TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium:    const TextStyle(color: textMuted,   fontSize: 14),
        bodySmall:     const TextStyle(color: textMuted,   fontSize: 12),
        labelLarge:    const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium:   const TextStyle(color: textMuted,   fontSize: 12),
        labelSmall:    const TextStyle(color: textDim,     fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color:     bgCard,
        elevation: 0,
        margin:    EdgeInsets.zero,
        shape:     RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:     true,
        fillColor:  Colors.white.withOpacity(0.04),
        hintStyle:  const TextStyle(color: textDim),
        labelStyle: const TextStyle(color: textMuted),
        border:          _inputBorder(borderColor),
        enabledBorder:   _inputBorder(borderColor),
        focusedBorder:   _inputBorder(goldPrimary),
        errorBorder:     _inputBorder(colorRed),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldPrimary,
          foregroundColor: Colors.black,
          elevation:       0,
          padding:         const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:       const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side:            const BorderSide(color: borderColor),
          padding:         const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: goldPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:  bgDark.withOpacity(0.95),
        elevation:        0,
        centerTitle:      false,
        iconTheme:        const IconThemeData(color: textPrimary),
        titleTextStyle:   const TextStyle(
          fontFamily: 'Orbitron', color: textPrimary,
          fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:     bgCard,
        selectedItemColor:   goldPrimary,
        unselectedItemColor: textMuted,
        elevation:           0,
      ),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor:   bgCard,
        selectedColor:     goldPrimary.withOpacity(0.2),
        labelStyle:        const TextStyle(color: textMuted, fontSize: 12),
        side:              const BorderSide(color: borderColor),
        shape:             RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding:           const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:  bgCard,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior:         SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor:   bgCard,
        elevation:         0,
        shape:             RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: goldPrimary),
    );
  }

  static ThemeData light() {
    return ThemeData.light().copyWith(
      primaryColor: goldPrimary,
      colorScheme: const ColorScheme.light(
        primary:   goldPrimary,
        secondary: goldDark,
        surface:   Color(0xFFF8F9FA),
        background: Color(0xFFFFFFFF),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  // Gradient helpers
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldPrimary, goldLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [bgDark, bgCard],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient escrowGradient = LinearGradient(
    colors: [colorPurple.withOpacity(0.1), colorBlue.withOpacity(0.1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
