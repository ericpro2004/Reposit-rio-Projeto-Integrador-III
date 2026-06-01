import 'package:flutter/material.dart';

/// Botão grande e acessível usado em toda a aplicação.
///
/// Garante por construção:
/// - alvo de toque ≥ 48 dp de altura (aqui 56 para conforto);
/// - rótulo semântico explícito para leitores de tela (TalkBack/VoiceOver);
/// - ícone opcional sempre acompanhado de texto (nunca só cor/ícone);
/// - estado de carregamento anunciado.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.semanticLabel,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final String? semanticLabel;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(label, textAlign: TextAlign.center),
              ),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary =>
        ElevatedButton(onPressed: isLoading ? null : onPressed, child: child),
      AppButtonVariant.outlined =>
        OutlinedButton(onPressed: isLoading ? null : onPressed, child: child),
      AppButtonVariant.text =>
        TextButton(onPressed: isLoading ? null : onPressed, child: child),
    };

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: semanticLabel ?? label,
      // Anuncia estado de carregamento para o leitor de tela.
      hint: isLoading ? 'Carregando, aguarde' : null,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: 56,
        child: button,
      ),
    );
  }
}

enum AppButtonVariant { primary, outlined, text }
