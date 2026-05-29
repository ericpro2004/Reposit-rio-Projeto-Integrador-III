import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Tema do app construído sobre Material 3 com acessibilidade nativa:
///   - Alvos de toque mínimos de 48x48 dp (botões e inputs).
///   - Tipografia legível, com tamanhos base generosos.
///   - Contraste validado (ver AppColors).
///   - Variante escura (Dark Mode) adaptada.
class AppTheme {
  AppTheme._();

  // Garante área de toque mínima de 48dp em todos os botões.
  static const Size _minTouch = Size(48, 48);
  static const VisualDensity _density = VisualDensity.standard;

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.safety,
      brightness: brightness,
      primary: AppColors.safety,
      onPrimary: AppColors.graphite, // texto preto sobre o laranja → alto contraste
      secondary: AppColors.safetyDark,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      onSurface: isDark ? AppColors.darkOnSurface : AppColors.graphite,
      error: AppColors.danger,
    );

    final textColor = isDark ? AppColors.darkOnSurface : AppColors.graphite;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      visualDensity: _density,
      splashFactory: InkRipple.splashFactory,

      // Tipografia base — corpo confortável (16sp) e títulos fortes.
      textTheme: _textTheme(textColor),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.safety,
        foregroundColor: AppColors.graphite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: AppColors.graphite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safety,
          foregroundColor: AppColors.graphite,
          minimumSize: const Size(double.infinity, 56),
          fixedSize: null,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ).copyWith(
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          minimumSize: const Size(double.infinity, 56),
          side: BorderSide(color: textColor.withValues(alpha: 0.4), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.safety : AppColors.safetyDark,
          minimumSize: _minTouch,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
        // Altura mínima confortável (>=48dp) para o alvo de toque.
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey500),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey500),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.safetyDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: TextStyle(color: textColor, fontSize: 16),
        hintStyle: const TextStyle(color: AppColors.grey500, fontSize: 16),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardTheme(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      displaySmall: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800, color: color),
      headlineMedium: TextStyle(
          fontSize: 26, fontWeight: FontWeight.w700, color: color),
      titleLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: color),
      titleMedium: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: color),
      bodyLarge: TextStyle(fontSize: 17, height: 1.4, color: color),
      bodyMedium: TextStyle(fontSize: 16, height: 1.4, color: color),
      labelLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: color),
    );
  }
}
