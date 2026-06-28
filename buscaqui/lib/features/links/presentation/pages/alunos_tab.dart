import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/links_provider.dart';

/// Aba "Alunos" (responsável): lista os alunos sob sua responsabilidade,
/// com a van e o motorista de cada. Para adicionar, usar o botão central.
class AlunosTab extends ConsumerWidget {
  const AlunosTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(myLinksProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myLinksProvider.future),
      child: linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: const [
          SizedBox(height: 120),
          Center(child: Text('Não foi possível carregar seus alunos.')),
        ]),
        data: (data) {
          final alunos = (data['alunos'] as List? ?? [])
              .map((e) => (e as Map).cast<String, dynamic>())
              .toList();
          if (alunos.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                Icon(Icons.family_restroom, size: 64),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Você ainda não é responsável por nenhum aluno.\n'
                    'Toque no botão central "Vincular" e informe o código do aluno.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final a in alunos) _AlunoCard(aluno: a),
            ],
          );
        },
      ),
    );
  }
}

class _AlunoCard extends StatelessWidget {
  const _AlunoCard({required this.aluno});
  final Map<String, dynamic> aluno;

  @override
  Widget build(BuildContext context) {
    final idade = (aluno['idade'] as num?)?.toInt();
    final temVan = aluno['van'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: avatar + nome + idade.
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  child: Icon(Icons.school, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aluno['nome']?.toString() ?? 'Aluno',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        idade != null ? '$idade anos' : 'Aluno',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Selo de situação do vínculo com a van.
                _StatusPill(emVan: temVan),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.directions_bus,
              label: 'Van',
              value: aluno['van']?.toString() ?? 'Sem van vinculada',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.badge,
              label: 'Motorista',
              value: aluno['motorista']?.toString() ?? 'Sem motorista',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.emVan});
  final bool emVan;

  @override
  Widget build(BuildContext context) {
    final cor = emVan ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(emVan ? Icons.check_circle : Icons.remove_circle_outline,
              size: 14, color: cor),
          const SizedBox(width: 4),
          Text(
            emVan ? 'Na van' : 'Sem van',
            style: TextStyle(
                color: cor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryAccessibleText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
