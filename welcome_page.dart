import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_buttons.dart';

/// Tela 1 (conteúdo de entrada) — Login inicial.
///
/// Logo centralizada, fundo laranja moderno e dois botões grandes:
/// "Criar minha conta" e "Já tenho uma conta".
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.safety,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Bloco da marca (um único nó semântico de cabeçalho).
              Semantics(
                header: true,
                label: 'BusCaqui, mobilidade escolar com segurança',
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        color: AppColors.graphite,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        size: 58,
                        color: AppColors.safety,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ExcludeSemantics(
                      child: Text(
                        'BusCaqui',
                        style: textTheme.displaySmall
                            ?.copyWith(color: AppColors.graphite),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExcludeSemantics(
                      child: Text(
                        'Mobilidade escolar com segurança',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge
                            ?.copyWith(color: AppColors.grey700),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Ações principais — botões grandes (>=56dp) e descritivos.
              AppPrimaryButton(
                label: 'Criar minha conta',
                icon: Icons.person_add_alt_1_rounded,
                semanticLabel: 'Criar minha conta. Abre o cadastro.',
                onPressed: () => context.push(AppRoutes.register),
              ),
              const SizedBox(height: 16),
              _LightOutlinedButton(
                label: 'Já tenho uma conta',
                semanticLabel: 'Já tenho uma conta. Abre a tela de login.',
                onPressed: () => context.push(AppRoutes.login),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão de contorno em fundo laranja: borda e texto pretos para manter
/// contraste alto (texto preto sobre laranja ≈ 7.9:1).
class _LightOutlinedButton extends StatelessWidget {
  const _LightOutlinedButton({
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.graphite,
            minimumSize: const Size(double.infinity, 56),
            side: const BorderSide(color: AppColors.graphite, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
