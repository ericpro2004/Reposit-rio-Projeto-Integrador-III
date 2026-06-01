import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../domain/entities/conexao.dart';

/// Card de uma conexão (Tela 5). Mostra nome, código, nº de passageiros e o
/// botão proeminente "Ver Localização". Para motorista, também o atalho de QR.
class ConnectionCard extends StatelessWidget {
  const ConnectionCard({
    super.key,
    required this.conexao,
    required this.isMotorista,
  });

  final Conexao conexao;
  final bool isMotorista;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Conexão ${conexao.nomeConexao}, '
          'código ${conexao.codigo}, '
          '${conexao.totalPassageiros} passageiros.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: const Icon(Icons.directions_bus),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(conexao.nomeConexao,
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          '${conexao.totalPassageiros} passageiro(s)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CodeChip(codigo: conexao.codigo),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.tracking,
                        extra: conexao,
                      ),
                      icon: const Icon(Icons.location_on),
                      label: const Text('Ver Localização'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  if (isMotorista) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: 'Gerar QR Code da conexão ${conexao.nomeConexao}',
                      child: IconButton.filledTonal(
                        iconSize: 26,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => context.push(
                          AppRoutes.qrGenerator,
                          extra: conexao,
                        ),
                        icon: const Icon(Icons.qr_code_2),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.codigo});
  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tag, size: 18),
          const SizedBox(width: 6),
          Text(
            'Código: $codigo',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
