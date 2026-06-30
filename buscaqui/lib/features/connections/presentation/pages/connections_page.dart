import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/conexao.dart';
import '../providers/connection_providers.dart';
import '../widgets/connection_card.dart';
import '../widgets/create_connection_sheet.dart';

/// Aba "Início" — Minhas Conexões. Conteúdo da aba (a barra superior/inferior
/// vem da casca de navegação). Motorista cria conexões; passageiro vê suas vans.
class ConnectionsPage extends ConsumerWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(myConnectionsProvider);
    final role = ref.watch(currentAppUserProvider).valueOrNull?.role;
    final isMotorista = role == UserRole.motorista;

    return RefreshIndicator(
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
          onCreate: () => _openCreateSheet(context, ref),
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
}

class _Content extends StatefulWidget {
  const _Content({
    required this.conexoes,
    required this.isMotorista,
    required this.onCreate,
  });

  final List<Conexao> conexoes;
  final bool isMotorista;
  final VoidCallback onCreate;

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conexoes = widget.conexoes;
    final q = _query.trim().toLowerCase();
    final filtradas = q.isEmpty
        ? conexoes
        : conexoes
            .where((c) =>
                c.nomeConexao.toLowerCase().contains(q) ||
                c.codigo.toLowerCase().contains(q))
            .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.isMotorista) ...[
          AppButton(
            label: 'Nova conexão',
            icon: Icons.add,
            onPressed: widget.onCreate,
          ),
          const SizedBox(height: 16),
        ],
        if (conexoes.isEmpty)
          const _EmptyState()
        else ...[
          // Barra de pesquisa (filtra por nome ou código da van).
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar van por nome ou código',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (filtradas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  const Icon(Icons.search_off, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhuma van encontrada para "$_query".',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            )
          else
            for (final c in filtradas)
              ConnectionCard(conexao: c, isMotorista: widget.isMotorista),
        ],
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
            'Use a aba "Conexão" para entrar com o código do motorista.',
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
