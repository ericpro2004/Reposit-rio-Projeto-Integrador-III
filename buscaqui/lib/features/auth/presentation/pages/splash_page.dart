import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';

/// Tela 1 — Splash / Login inicial.
///
/// Acessibilidade:
/// - Fundo laranja de marca com texto/ícones em preto suave (contraste AA).
/// - Logo com `Semantics` (label e imagem anunciada ao leitor de tela).
/// - Botões grandes (56 dp) com rótulos descritivos.
/// - Escala de texto respeitada via `MediaQuery.textScaler` (sem tamanhos
///   "travados"); `SingleChildScrollView` evita overflow quando o usuário
///   amplia a fonte.
/// - Se já houver sessão ativa, redireciona automaticamente para as conexões.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Após o primeiro frame, decide o destino com base na sessão.
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideStartRoute());
  }

  void _decideStartRoute() {
    if (!mounted) return;
    final isAuthed = ref.read(isAuthenticatedProvider);
    if (isAuthed) {
      context.go(AppRoutes.connections);
    }
    // Se não autenticado, permanece exibindo as ações de entrada.
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Limita a ampliação a 1.4x para preservar o layout sem cortar conteúdo.
    final clampedScale =
        mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.4);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: MediaQuery(
        data: mq.copyWith(textScaler: clampedScale),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                // minHeight = altura disponível menos o padding vertical (48).
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                // IntrinsicHeight dá altura limitada ao Column, permitindo o
                // uso de Spacer/flex mesmo dentro de um scroll view.
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                  const Spacer(flex: 2),
                  _Logo(),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      'BusCaqui',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(color: AppColors.onPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transporte escolar seguro, monitorado em tempo real.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onPrimary,
                        ),
                  ),
                  const Spacer(flex: 3),
                  // Ação primária: usa superfície clara para contrastar com o
                  // fundo laranja, com texto laranja-escuro acessível.
                  Semantics(
                    button: true,
                    label: 'Criar minha conta. Abre a tela de cadastro.',
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.background,
                          foregroundColor: AppColors.primaryAccessibleText,
                        ),
                        onPressed: () => context.push(AppRoutes.register),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Criar minha conta'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Ação secundária: contorno escuro sobre o fundo laranja.
                  Semantics(
                    button: true,
                    label: 'Já tenho uma conta. Abre a tela de login.',
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onPrimary,
                          side: const BorderSide(
                              color: AppColors.onPrimary, width: 1.8),
                        ),
                        onPressed: () => context.push(AppRoutes.login),
                        icon: const Icon(Icons.login),
                        label: const Text('Já tenho uma conta'),
                      ),
                    ),
                  ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder do logo. Substituir por Image.asset('assets/images/logo.png')
    // mantendo o Semantics com a descrição da imagem.
    return Semantics(
      label: 'Logotipo do aplicativo BusCaqui',
      image: true,
      child: Container(
        height: 120,
        width: 120,
        decoration: const BoxDecoration(
          color: AppColors.onPrimary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.directions_bus_rounded,
          size: 64,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
