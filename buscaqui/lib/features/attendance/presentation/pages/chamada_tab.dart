import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../connections/presentation/providers/connection_providers.dart';
import '../widgets/roster_view.dart';

/// Aba "Chamada" (motorista). Seleciona a van e mostra o roster em tempo real:
/// os check-ins por QR aparecem sozinhos e há marcação manual.
class ChamadaTab extends ConsumerStatefulWidget {
  const ChamadaTab({super.key});

  @override
  ConsumerState<ChamadaTab> createState() => _ChamadaTabState();
}

class _ChamadaTabState extends ConsumerState<ChamadaTab> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(myConnectionsProvider);

    return connectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppButton(
            label: 'Tentar novamente',
            icon: Icons.refresh,
            expand: false,
            onPressed: () => ref.invalidate(myConnectionsProvider),
            semanticLabel: e is Failure ? e.message : 'Erro ao carregar.',
          ),
        ),
      ),
      data: (conexoes) {
        if (conexoes.isEmpty) {
          return _Empty();
        }
        // Seleção padrão = primeira van; mantém a escolha do motorista.
        final selected = conexoes.firstWhere(
          (c) => c.id == _selectedId,
          orElse: () => conexoes.first,
        );
        return Column(
          children: [
            if (conexoes.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: DropdownButtonFormField<String>(
                  value: selected.id,
                  decoration: const InputDecoration(
                    labelText: 'Van',
                    prefixIcon: Icon(Icons.directions_bus),
                  ),
                  items: [
                    for (final c in conexoes)
                      DropdownMenuItem(value: c.id, child: Text(c.nomeConexao)),
                  ],
                  onChanged: (id) => setState(() => _selectedId = id),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(selected.nomeConexao,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
            Expanded(child: RosterView(conexaoId: selected.id)),
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checklist_rtl, size: 64),
            const SizedBox(height: 16),
            Text(
              'Você ainda não tem nenhuma van.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie uma conexão na aba Início para fazer a chamada.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
