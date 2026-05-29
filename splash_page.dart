import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

/// Tela 1 — Splash Screen.
///
/// Mostra a marca por um breve instante, verifica se há sessão ativa no
/// Supabase e encaminha o usuário:
///   - com sessão  -> /connections (Minhas Conexões)
///   - sem sessão   -> /welcome     (boas-vindas com os botões de conta)
///
/// Acessibilidade:
///   - `Semantics(header: true)` no nome da marca e descrição completa via
///     `liveRegion` no indicador de carregamento, lido por TalkBack/VoiceOver.
///   - Fundo laranja de segurança com logo e texto em preto suave
///     (contraste ~7.9:1, aprova WCAG AA).
///   - Nenhum texto fica abaixo do alvo legível; respeita a escala dinâmica.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _decideStartDestination();
  }

  Future<void> _decideStartDestination() async {
    // Tempo mínimo de marca, sem travar a thread de UI.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final session = ref.read(supabaseClientProvider).auth.currentSession;
    final destino = session != null ? AppRoutes.connections : AppRoutes.welcome;

    if (mounted) context.go(destino);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.safety,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Marca / logo
                Semantics(
                  header: true,
                  label: 'BusCaqui, mobilidade escolar com segurança',
                  child: Column(
                    children: [
                      const _BrandLogo(),
                      const SizedBox(height: 24),
                      ExcludeSemantics(
                        child: Text(
                          'BusCaqui',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(color: AppColors.graphite),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ExcludeSemantics(
                        child: Text(
                          'Mobilidade escolar com segurança',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.grey700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Indicador de carregamento anunciado a leitores de tela.
                Semantics(
                  liveRegion: true,
                  label: 'Carregando o aplicativo',
                  child: const SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.graphite),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo em círculo escuro com ícone de transporte (preto sobre laranja).
class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        color: AppColors.graphite,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.directions_bus_rounded,
        size: 64,
        color: AppColors.safety,
      ),
    );
  }
}
