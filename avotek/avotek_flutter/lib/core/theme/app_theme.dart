import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors from AVOTEK Logo
  static const Color primaryCyan = Color(0xFF1687D9); // Brand Cyan
  static const Color electricCyan = Color(0xFF2A9BE8); // Accent Blue
  static const Color primaryBlue = Color(0xFF2563EB); // Royal Blue
  static const Color deepElectricBlue = Color(0xFF1976C9);
  static const Color slateGrey = Color(0xFF64748B); // Circuit Grey
  static const Color metallicLight = Color(0xFF94A3B8);
  static const Color darkBg = Color(0xFF0A0E17); // Deep Obsidian
  static const Color darkCard = Color(0xFF111827); // Midnight Card Surface
  static const Color darkCardVariant = Color(0xFF182234);
  static const Color darkBorder = Color(0xFF26334D);

  static const Color lightBg = Color(0xFFF8FAFC); // Slate Pearl
  static const Color lightCard = Color(0xFFFFFFFF); // Pure Crisp White
  static const Color lightCardVariant = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Semantics
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Crimson
  static const Color info = Color(0xFF00A3FF);

  // Networks
  static const Color mtnYellow = Color(0xFFFFCC00);
  static const Color airtelRed = Color(0xFFE60000);
  static const Color gloGreen = Color(0xFF00A859);
  static const Color nineMobileGreen = Color(0xFF005B38);
}

class AppTheme {
  static TextTheme _buildFigtreeTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? AppColors.metallicLight : AppColors.slateGrey;
    final base = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final baseFontTheme = GoogleFonts.figtreeTextTheme(base);

    final textTheme = baseFontTheme.copyWith(
      displayLarge: GoogleFonts.figtree(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: primaryTextColor,
      ),
      displayMedium: GoogleFonts.figtree(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: primaryTextColor,
      ),
      displaySmall: GoogleFonts.figtree(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: primaryTextColor,
      ),
      headlineLarge: GoogleFonts.figtree(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: primaryTextColor,
      ),
      headlineMedium: GoogleFonts.figtree(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primaryTextColor,
      ),
      headlineSmall: GoogleFonts.figtree(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: primaryTextColor,
      ),
      titleLarge: GoogleFonts.figtree(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.1,
        color: primaryTextColor,
      ),
      titleMedium: GoogleFonts.figtree(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: primaryTextColor,
      ),
      titleSmall: GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        color: secondaryTextColor,
      ),
      bodyLarge: GoogleFonts.figtree(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primaryTextColor,
      ),
      bodyMedium: GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: secondaryTextColor,
      ),
      bodySmall: GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: secondaryTextColor,
      ),
      labelLarge: GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: primaryTextColor,
      ),
      labelMedium: GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.figtree(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: secondaryTextColor,
      ),
    );
    final spacedTextTheme = textTheme.apply(
      fontFamily: 'Figtree',
      letterSpacingDelta: 0.1,
    );
    return spacedTextTheme.copyWith(
      displayLarge: spacedTextTheme.displayLarge?.copyWith(wordSpacing: 0.2),
      displayMedium: spacedTextTheme.displayMedium?.copyWith(wordSpacing: 0.2),
      displaySmall: spacedTextTheme.displaySmall?.copyWith(wordSpacing: 0.2),
      headlineLarge: spacedTextTheme.headlineLarge?.copyWith(wordSpacing: 0.2),
      headlineMedium: spacedTextTheme.headlineMedium?.copyWith(wordSpacing: 0.2),
      headlineSmall: spacedTextTheme.headlineSmall?.copyWith(wordSpacing: 0.2),
      titleLarge: spacedTextTheme.titleLarge?.copyWith(wordSpacing: 0.2),
      titleMedium: spacedTextTheme.titleMedium?.copyWith(wordSpacing: 0.2),
      titleSmall: spacedTextTheme.titleSmall?.copyWith(wordSpacing: 0.2),
      bodyLarge: spacedTextTheme.bodyLarge?.copyWith(wordSpacing: 0.2),
      bodyMedium: spacedTextTheme.bodyMedium?.copyWith(wordSpacing: 0.2),
      bodySmall: spacedTextTheme.bodySmall?.copyWith(wordSpacing: 0.2),
      labelLarge: spacedTextTheme.labelLarge?.copyWith(wordSpacing: 0.2),
      labelMedium: spacedTextTheme.labelMedium?.copyWith(wordSpacing: 0.2),
      labelSmall: spacedTextTheme.labelSmall?.copyWith(wordSpacing: 0.2),
    );
  }

  static ThemeData light() {
    final textTheme = _buildFigtreeTextTheme(Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Figtree',
      fontFamilyFallback: [GoogleFonts.figtree().fontFamily ?? 'Figtree', 'Public Sans', 'sans-serif'],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primaryBlue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE0F2FE),
        onPrimaryContainer: Color(0xFF0369A1),
        secondary: AppColors.slateGrey,
        onSecondary: Colors.white,
        surface: AppColors.lightCard,
        onSurface: Color(0xFF0F172A),
        surfaceContainerHighest: AppColors.lightCardVariant,
        outline: AppColors.lightBorder,
        error: AppColors.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.figtree(
          color: const Color(0xFF0F172A),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: AppColors.lightCard,
        indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.figtree(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryBlue : AppColors.slateGrey,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 20,
            color: isSelected ? AppColors.primaryBlue : AppColors.slateGrey,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCardVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        hintStyle: GoogleFonts.figtree(
          color: const Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.figtree(
          color: const Color(0xFF475569),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.figtree(
          color: AppColors.primaryBlue,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        titleTextStyle: GoogleFonts.figtree(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
        contentTextStyle: GoogleFonts.figtree(
          fontSize: 13.5,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final textTheme = _buildFigtreeTextTheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Figtree',
      fontFamilyFallback: [GoogleFonts.figtree().fontFamily ?? 'Figtree', 'Public Sans', 'sans-serif'],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryCyan,
        onPrimary: Color(0xFF002B47),
        primaryContainer: Color(0xFF00385C),
        onPrimaryContainer: Color(0xFFBEE3F8),
        secondary: AppColors.metallicLight,
        onSecondary: Color(0xFF0A0E17),
        surface: AppColors.darkCard,
        onSurface: Color(0xFFF8FAFC),
        surfaceContainerHighest: AppColors.darkCardVariant,
        outline: AppColors.darkBorder,
        error: AppColors.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.figtree(
          color: const Color(0xFFF8FAFC),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: AppColors.darkCard,
        indicatorColor: AppColors.primaryCyan.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.figtree(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryCyan : AppColors.metallicLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 20,
            color: isSelected ? AppColors.primaryCyan : AppColors.metallicLight,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCardVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
        hintStyle: GoogleFonts.figtree(
          color: const Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.figtree(
          color: const Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.figtree(
          color: AppColors.primaryCyan,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryCyan,
          foregroundColor: const Color(0xFF002B47),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.figtree(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        titleTextStyle: GoogleFonts.figtree(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        contentTextStyle: GoogleFonts.figtree(
          fontSize: 13.5,
          color: const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
