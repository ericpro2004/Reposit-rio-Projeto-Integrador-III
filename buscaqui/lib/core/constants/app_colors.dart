import 'package:flutter/material.dart';

/// Paleta central do BusCaqui.
///
/// Regra de ouro de acessibilidade (WCAG AA — contraste mínimo 4.5:1):
///   - O laranja/amarelo de segurança é SEMPRE fundo, nunca texto sobre
///     branco (laranja sobre branco ~1.9:1 → reprova). Por isso os botões
///     usam fundo laranja + texto preto suave (~7.9:1 → aprova).
///   - Texto principal é o preto suave [graphite] sobre claro, e branco
///     puro sobre escuro.
class AppColors {
  AppColors._();

  // Cor principal — Laranja/Amarelo Segurança.
  static const Color safety = Color(0xFFF5A623);
  static const Color safetyDark = Color(0xFFD98B0C); // estado pressionado/hover
  static const Color safetyContainer = Color(0xFFFFE8C2);

  // Neutros
  static const Color graphite = Color(0xFF212121); // texto/detalhes (preto suave)
  static const Color grey700 = Color(0xFF424242);
  static const Color grey500 = Color(0xFF757575); // texto secundário (≈4.6:1 no branco)
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color background = Color(0xFFF7F7F8); // cinza claro
  static const Color surface = Color(0xFFFFFFFF);

  // Status (sempre acompanhados de ícone + label, nunca só a cor)
  static const Color success = Color(0xFF1B7F4B); // presente   (~4.6:1 no branco)
  static const Color danger = Color(0xFFC62828); // ausente    (~5.9:1 no branco)
  static const Color info = Color(0xFF1565C0); // justificado(~5.6:1 no branco)

  // Dark mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFF2F2F2);
}
