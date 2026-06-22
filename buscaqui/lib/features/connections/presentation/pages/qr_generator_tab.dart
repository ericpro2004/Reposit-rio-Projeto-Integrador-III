import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/connection_providers.dart';
import '../widgets/qr_generator_view.dart';

/// Aba "Gerar QR" (motorista). Seleciona a van e mostra o QR para os passageiros.
class QrGeneratorTab extends ConsumerStatefulWidget {
  const QrGeneratorTab({super.key});

  @override
  ConsumerState<QrGeneratorTab> createState() => _QrGeneratorTabState();
}

class _QrGeneratorTabState extends ConsumerState<QrGeneratorTab> {
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_2, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Crie uma conexão na aba Início para gerar o QR.',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
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
              ),
            Expanded(child: QrGeneratorView(conexao: selected)),
          ],
        );
      },
    );
  }
}
