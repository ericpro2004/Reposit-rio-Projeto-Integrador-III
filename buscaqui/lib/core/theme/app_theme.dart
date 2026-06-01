import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Temas claro e escuro do BusCaqui, construídos com acessibilidade nativa:
/// - Alvos de toque mínimos de 48x48 dp (botões, inputs, ícones).
/// - Tipografia legível (Inter) com tamanhos base ≥ 14sp.
/// - Contrastes AA garantidos pela paleta em [AppColors].
abstract final class AppTheme {
  /// Tamanho mínimo de alvo de toque exigido por WCAG 2.5.5 / Material.
  static const Size _minTouchTarget = Size(48, 48);
  static const double _radius = 14;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.primaryOnDark : AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: isDark ? AppColors.primaryOnDark : AppColors.primaryDark,
      onSecondary: AppColors.onPrimary,
      error: AppColors.danger,
      onError: Colors.white,
      surface: isDark ? AppColors.darkSurface : AppColors.background,
      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
    );

    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      fontFamily: 'Inter',

      // Garante que o usuário possa ampliar o texto até 1.3x sem quebra grave.
      visualDensity: VisualDensity.comfortable,

      textTheme: _textTheme(textColor, secondaryText),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: _minTouchTarget,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: _minTouchTarget,
          foregroundColor: isDark
              ? AppColors.primaryOnDark
              : AppColors.primaryAccessibleText,
          side: BorderSide(color: colorScheme.primary, width: 1.6),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: _minTouchTarget,
          foregroundColor: isDark
              ? AppColors.primaryOnDark
              : AppColors.primaryAccessibleText,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 56),
        labelStyle: TextStyle(color: secondaryText, fontSize: 16),
        hintStyle: TextStyle(color: secondaryText, fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.background,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),

      cardTheme: CardTheme(
        color: isDark ? AppColors.darkSurface : AppColors.background,
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(
            color: isDark ? Colors.white12 : AppColors.border,
          ),
        ),
      ),

      iconTheme: IconThemeData(color: textColor, size: 24),
      dividerTheme: const DividerThemeData(thickness: 1, space: 1),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displaySmall: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700, color: primary),
      headlineMedium: TextStyle(
          fontSize: 26, fontWeight: FontWeight.w700, color: primary),
      titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(fontSize: 17, height: 1.4, color: primary),
      bodyMedium: TextStyle(fontSize: 15, height: 1.4, color: primary),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: secondary),
    );
  }
}
