import 'package:flutter/material.dart';

/// Paleta de cores do BusCaqui com foco em acessibilidade WCAG 2.1 nível AA.
///
/// ⚠️ NOTA CRÍTICA DE CONTRASTE:
/// O laranja de marca (#F5A623) tem contraste de apenas ~1.9:1 contra o branco.
/// Por isso ele NUNCA é usado como cor de texto sobre fundo claro, e texto
/// sobre botões laranja é sempre o preto suave (#212121 → contraste ~8.3:1),
/// não branco. Para texto/links de ação sobre fundo claro usamos
/// [primaryAccessibleText] (#A8650A → contraste ~4.6:1).
abstract final class AppColors {
  // ---- Marca ----
  /// Laranja de segurança — uso em superfícies/preenchimentos, não em texto fino.
  static const Color primary = Color(0xFFF5A623);
  static const Color primaryDark = Color(0xFFD98E0B);

  /// Laranja escurecido aprovado para TEXTO e ícones finos sobre fundo claro
  /// (contraste ≥ 4.5:1).
  static const Color primaryAccessibleText = Color(0xFFA8650A);

  // ---- Neutros ----
  static const Color textPrimary = Color(0xFF212121); // preto suave
  static const Color textSecondary = Color(0xFF5C5C5C); // ~7:1 sobre branco
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF4F5F7); // cinza claro
  static const Color border = Color(0xFFD0D5DD);

  // ---- Texto sobre o laranja ----
  /// Cor de texto/ícone usada por cima de [primary]. Preto suave para AA.
  static const Color onPrimary = Color(0xFF212121);

  // ---- Estados semânticos (sempre acompanhados de ícone + label) ----
  static const Color success = Color(0xFF1B7A3D); // presente
  static const Color danger = Color(0xFFC62828); // ausente
  static const Color warning = Color(0xFF9A6700); // justificado
  static const Color info = Color(0xFF1A5FB4);

  // ---- Dark Mode ----
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFF2F2F2);
  static const Color darkTextSecondary = Color(0xFFB8B8B8);

  /// Laranja mais claro/saturado para garantir contraste em fundo escuro.
  static const Color primaryOnDark = Color(0xFFFFB94E);
}
