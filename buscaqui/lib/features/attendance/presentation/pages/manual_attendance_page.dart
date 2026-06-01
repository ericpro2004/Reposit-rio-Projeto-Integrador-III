import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/presenca.dart';
import '../providers/attendance_providers.dart';
import '../widgets/status_tag.dart';

enum _Filter { todos, presentes, ausentes }

/// Tela 9 — Chamada Manual (motorista). Lista de passageiros com foto, nome e
/// status; botões rápidos Presente/Ausente; filtros e tags de origem.
class ManualAttendancePage extends ConsumerStatefulWidget {
  const ManualAttendancePage({
    super.key,
    required this.conexaoId,
    required this.nomeConexao,
  });

  final String conexaoId;
  final String nomeConexao;

  @override
  ConsumerState<ManualAttendancePage> createState() =>
      _ManualAttendancePageState();
}

class _ManualAttendancePageState extends ConsumerState<ManualAttendancePage> {
  _Filter _filter = _Filter.todos;

  bool _matches(RosterItem item) => switch (_filter) {
        _Filter.todos => true,
        _Filter.presentes => item.status == PresencaStatus.presente,
        _Filter.ausentes => item.status != PresencaStatus.presente,
      };

  Future<void> _mark(String id, PresencaStatus status) async {
    final erro = await ref
        .read(rosterControllerProvider(widget.conexaoId).notifier)
        .mark(id, status);
    if (!mounted) return;
    if (erro != null) {
      showAppFeedback(context, erro, type: FeedbackType.error);
    } else {
      showAppFeedback(
        context,
        status == PresencaStatus.presente
            ? 'Presença registrada.'
            : 'Ausência registrada.',
        type: FeedbackType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(rosterControllerProvider(widget.conexaoId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Chamada — ${widget.nomeConexao}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _FilterBar(
            value: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
        ),
      ),
      body: rosterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppButton(
              label: 'Tentar novamente',
              icon: Icons.refresh,
              expand: false,
              onPressed: () =>
                  ref.invalidate(rosterControllerProvider(widget.conexaoId)),
              semanticLabel: e is Failure ? e.message : 'Erro ao carregar.',
            ),
          ),
        ),
        data: (roster) {
          final visible = roster.where(_matches).toList();
          if (visible.isEmpty) {
            return Center(
              child: Text(
                roster.isEmpty
                    ? 'Nenhum passageiro nesta conexão ainda.'
                    : 'Nenhum passageiro neste filtro.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: visible.length,
            itemBuilder: (_, i) => _RosterTile(
              item: visible[i],
              onPresente: () => _mark(visible[i].passageiroId, PresencaStatus.presente),
              onAusente: () => _mark(visible[i].passageiroId, PresencaStatus.ausente),
            ),
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});
  final _Filter value;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SegmentedButton<_Filter>(
        segments: const [
          ButtonSegment(value: _Filter.todos, label: Text('Todos')),
          ButtonSegment(value: _Filter.presentes, label: Text('Presentes')),
          ButtonSegment(value: _Filter.ausentes, label: Text('Ausentes')),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

class _RosterTile extends StatelessWidget {
  const _RosterTile({
    required this.item,
    required this.onPresente,
    required this.onAusente,
  });

  final RosterItem item;
  final VoidCallback onPresente;
  final VoidCallback onAusente;

  @override
  Widget build(BuildContext context) {
    final isPresente = item.status == PresencaStatus.presente;
    final isAusente = item.status == PresencaStatus.ausente;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      item.fotoUrl != null ? NetworkImage(item.fotoUrl!) : null,
                  child: item.fotoUrl == null
                      ? Text(item.nome.isNotEmpty ? item.nome[0] : '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.nome,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          StatusTag(status: item.status),
                          if (item.origem != null)
                            OriginTag(origem: item.origem!),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Marcar ${item.nome} como presente',
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              isPresente ? AppColors.success : null,
                        ),
                        onPressed: onPresente,
                        icon: const Icon(Icons.check),
                        label: const Text('Presente'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Marcar ${item.nome} como ausente',
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(
                            color: isAusente
                                ? AppColors.danger
                                : AppColors.border,
                            width: isAusente ? 2 : 1.4,
                          ),
                        ),
                        onPressed: onAusente,
                        icon: const Icon(Icons.close),
                        label: const Text('Ausente'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
