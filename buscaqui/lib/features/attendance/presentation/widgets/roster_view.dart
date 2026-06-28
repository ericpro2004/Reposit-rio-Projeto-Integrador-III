import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/presenca.dart';
import '../providers/attendance_providers.dart';
import 'status_tag.dart';

enum _Filter { todos, presentes, ausentes }

/// Lista de chamada em tempo real de uma conexão. As presenças por QR aparecem
/// automaticamente; o motorista pode marcar presente/ausente manualmente.
class RosterView extends ConsumerStatefulWidget {
  const RosterView({super.key, required this.conexaoId});
  final String conexaoId;

  @override
  ConsumerState<RosterView> createState() => _RosterViewState();
}

class _RosterViewState extends ConsumerState<RosterView> {
  _Filter _filter = _Filter.todos;

  bool _matches(RosterItem item) => switch (_filter) {
        _Filter.todos => true,
        _Filter.presentes => item.status == PresencaStatus.presente,
        _Filter.ausentes => item.status != PresencaStatus.presente,
      };

  Future<void> _mark(String id, PresencaStatus status) async {
    // O stream atualiza a UI sozinho; aqui só persistimos e tratamos erro.
    final res = await ref
        .read(attendanceRepositoryProvider)
        .markAttendance(passageiroId: id, status: status);
    if (!mounted) return;
    res.match(
      (f) => showAppFeedback(context, f.message, type: FeedbackType.error),
      (_) {},
    );
  }

  Future<void> _justificar(RosterItem item) async {
    final controller = TextEditingController(text: item.justificativa ?? '');
    final texto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Justificativa — ${item.nome}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Ex.: Consulta médica; avisado pelos pais.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Enviar ao responsável'),
          ),
        ],
      ),
    );
    if (texto == null || texto.isEmpty) return;
    final res = await ref
        .read(attendanceRepositoryProvider)
        .setJustificativa(passageiroId: item.passageiroId, justificativa: texto);
    if (!mounted) return;
    res.match(
      (f) => showAppFeedback(context, f.message, type: FeedbackType.error),
      (_) => showAppFeedback(context, 'Justificativa enviada ao responsável.',
          type: FeedbackType.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(rosterStreamProvider(widget.conexaoId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SegmentedButton<_Filter>(
            segments: const [
              ButtonSegment(value: _Filter.todos, label: Text('Todos')),
              ButtonSegment(value: _Filter.presentes, label: Text('Presentes')),
              ButtonSegment(value: _Filter.ausentes, label: Text('Ausentes')),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
        ),
        Expanded(
          child: rosterAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppButton(
                  label: 'Tentar novamente',
                  icon: Icons.refresh,
                  expand: false,
                  onPressed: () =>
                      ref.invalidate(rosterStreamProvider(widget.conexaoId)),
                ),
              ),
            ),
            data: (roster) {
              final visible = roster.where(_matches).toList();
              if (visible.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      roster.isEmpty
                          ? 'Nenhum passageiro nesta conexão ainda.'
                          : 'Nenhum passageiro neste filtro.',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: visible.length,
                itemBuilder: (_, i) => _RosterTile(
                  item: visible[i],
                  onPresente: () =>
                      _mark(visible[i].passageiroId, PresencaStatus.presente),
                  onAusente: () =>
                      _mark(visible[i].passageiroId, PresencaStatus.ausente),
                  onJustificar: () => _justificar(visible[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RosterTile extends StatelessWidget {
  const _RosterTile({
    required this.item,
    required this.onPresente,
    required this.onAusente,
    required this.onJustificar,
  });

  final RosterItem item;
  final VoidCallback onPresente;
  final VoidCallback onAusente;
  final VoidCallback onJustificar;

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
                          backgroundColor: isPresente ? AppColors.success : null,
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
                            color: isAusente ? AppColors.danger : AppColors.border,
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
            // Justificativa (motorista): botão + texto, enviado ao responsável.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onJustificar,
                icon: const Icon(Icons.edit_note, size: 20),
                label: Text(
                  (item.justificativa?.isNotEmpty ?? false)
                      ? 'Editar justificativa'
                      : 'Adicionar justificativa',
                ),
              ),
            ),
            if (item.justificativa?.isNotEmpty ?? false)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Justificativa: ${item.justificativa}',
                  style: const TextStyle(color: AppColors.warning),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
