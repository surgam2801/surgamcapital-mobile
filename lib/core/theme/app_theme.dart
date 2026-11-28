import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static const mobileBreakpoint = 600.0;
  static final ThemeData _light = _createLight();

  static bool isMobileWidth(double width) => width < mobileBreakpoint;

  static TextTheme textThemeForWidth(double width, TextTheme textTheme) =>
      isMobileWidth(width) ? compactTextTheme(textTheme) : textTheme;

  static TextTheme compactTextTheme(TextTheme textTheme) => textTheme.copyWith(
    headlineLarge: textTheme.headlineLarge?.copyWith(fontSize: 30, height: 1.1),
    headlineMedium: textTheme.headlineMedium?.copyWith(
      fontSize: 26,
      height: 1.15,
    ),
    headlineSmall: textTheme.headlineSmall?.copyWith(fontSize: 22, height: 1.2),
    titleLarge: textTheme.titleLarge?.copyWith(fontSize: 18, height: 1.25),
    titleMedium: textTheme.titleMedium?.copyWith(fontSize: 15, height: 1.35),
    bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.4),
    bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.4),
    bodySmall: textTheme.bodySmall?.copyWith(height: 1.35),
  );

  static ThemeData forWidth(double width) {
    final theme = light;
    if (!isMobileWidth(width)) return theme;

    return theme.copyWith(
      textTheme: textThemeForWidth(width, theme.textTheme),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      listTileTheme: theme.listTileTheme.copyWith(minVerticalPadding: 8),
    );
  }

  static ThemeData get light => _light;

  static ThemeData _createLight() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.blue,
        secondary: AppColors.teal,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme()
          .apply(
            bodyColor: AppColors.primaryText,
            displayColor: AppColors.primaryText,
          )
          .copyWith(
            headlineLarge: GoogleFonts.inter(
              fontSize: 36,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
            headlineMedium: GoogleFonts.inter(
              fontSize: 30,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
            headlineSmall: GoogleFonts.inter(
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 20,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
            titleMedium: GoogleFonts.inter(
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
            bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.55),
            bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.5),
            bodySmall: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: AppColors.secondaryText,
            ),
            labelLarge: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.blue,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 12,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blue,
        linearTrackColor: Color(0xFFE2EBE8),
        circularTrackColor: Color(0xFFE2EBE8),
        linearMinHeight: 6,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.navy),
        selectedColor: AppColors.blue.withValues(alpha: .1),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.blue.withValues(alpha: .12),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.blue.withValues(alpha: .12),
        selectedIconTheme: const IconThemeData(color: AppColors.blue),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.secondaryText,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.secondaryText,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
