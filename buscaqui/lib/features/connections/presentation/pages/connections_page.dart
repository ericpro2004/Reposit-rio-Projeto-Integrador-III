import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../alerts/presentation/providers/alert_providers.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/conexao.dart';
import '../providers/connection_providers.dart';
import '../widgets/connection_card.dart';
import '../widgets/create_connection_sheet.dart';

/// Tela 5 — Minhas Conexões. Lista as vans vinculadas em cards. Motorista pode
/// criar conexões; passageiro/responsável pode entrar por código.
class ConnectionsPage extends ConsumerWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(myConnectionsProvider);
    final role = ref.watch(currentAppUserProvider).valueOrNull?.role;
    final isMotorista = role == UserRole.motorista;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Conexões'),
        actions: [
          IconButton(
            tooltip: 'Monitoramento',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => context.push(AppRoutes.dashboard),
          ),
          _AlertsAction(unread: ref.watch(unreadAlertsCountProvider)),
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      floatingActionButton: isMotorista
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nova conexão'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(myConnectionsProvider.future),
        child: connectionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: e is Failure ? e.message : 'Erro ao carregar conexões.',
            onRetry: () => ref.invalidate(myConnectionsProvider),
          ),
          data: (conexoes) => _Content(
            conexoes: conexoes,
            isMotorista: isMotorista,
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context, WidgetRef ref) async {
    final nome = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateConnectionSheet(),
    );
    if (nome == null || nome.isEmpty) return;

    final res = await ref.read(connectionControllerProvider.notifier).create(nome);
    if (!context.mounted) return;
    showAppFeedback(
      context,
      res.erro ?? 'Conexão "${res.conexao?.nomeConexao}" criada!',
      type: res.erro == null ? FeedbackType.success : FeedbackType.error,
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (sair != true || !context.mounted) return;

    await ref.read(authControllerProvider.notifier).signOut();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

/// Ícone de alertas com badge de não lidos (acessível via label dinâmico).
class _AlertsAction extends StatelessWidget {
  const _AlertsAction({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: unread > 0 ? 'Alertas, $unread não lidos' : 'Alertas',
      onPressed: () => context.push(AppRoutes.alerts),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.conexoes, required this.isMotorista});
  final List<Conexao> conexoes;
  final bool isMotorista;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!isMotorista) ...[
          AppButton(
            label: 'Registrar presença (ler QR)',
            icon: Icons.qr_code_scanner,
            onPressed: () => context.push(AppRoutes.qrScanner),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Entrar em uma conexão',
            icon: Icons.group_add,
            variant: AppButtonVariant.outlined,
            onPressed: () => context.push(AppRoutes.joinConnection),
          ),
          const SizedBox(height: 16),
        ],
        if (conexoes.isEmpty)
          const _EmptyState()
        else
          for (final c in conexoes)
            ConnectionCard(conexao: c, isMotorista: isMotorista),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.directions_bus_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            'Nenhuma conexão por aqui ainda.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Crie uma nova conexão ou entre em uma usando o código do motorista.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 96),
        const Icon(Icons.error_outline, size: 56),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        Center(
          child: AppButton(
            label: 'Tentar novamente',
            icon: Icons.refresh,
            expand: false,
            onPressed: onRetry,
          ),
        ),
      ],
    );
  }
}
