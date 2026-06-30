import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/presenca.dart';
import '../providers/attendance_providers.dart';
import 'status_tag.dart';

enum _Filter { todos, presentes, ausentes }

/// Lista de chamada em tempo real de uma conexão, com seletor de dia e relógio.
/// Cada dia é uma chamada separada (presenças por data); as presenças por QR
/// aparecem automaticamente e o motorista pode marcar manualmente.
class RosterView extends ConsumerStatefulWidget {
  const RosterView({super.key, required this.conexaoId});
  final String conexaoId;

  @override
  ConsumerState<RosterView> createState() => _RosterViewState();
}

class _RosterViewState extends ConsumerState<RosterView> {
  _Filter _filter = _Filter.todos;
  late DateTime _dia = _dateOnly(DateTime.now());
  DateTime _agora = DateTime.now();
  Timer? _timer;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    // Relógio ao vivo (atualiza a cada segundo).
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _agora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _dataStr => DateFormat('yyyy-MM-dd').format(_dia);
  bool get _ehHoje => _dia == _dateOnly(DateTime.now());

  bool _matches(RosterItem item) => switch (_filter) {
        _Filter.todos => true,
        _Filter.presentes => item.status == PresencaStatus.presente,
        _Filter.ausentes => item.status != PresencaStatus.presente,
      };

  void _mudarDia(int delta) {
    final novo = _dateOnly(_dia.add(Duration(days: delta)));
    // Não permite navegar para o futuro.
    if (novo.isAfter(_dateOnly(DateTime.now()))) return;
    setState(() => _dia = novo);
  }

  Future<void> _mark(String id, PresencaStatus status) async {
    final res = await ref.read(attendanceRepositoryProvider).markAttendance(
        passageiroId: id, status: status, data: _dataStr);
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
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Enviar ao responsável'),
          ),
        ],
      ),
    );
    if (texto == null || texto.isEmpty) return;
    final res = await ref.read(attendanceRepositoryProvider).setJustificativa(
        passageiroId: item.passageiroId, justificativa: texto, data: _dataStr);
    if (!mounted) return;
    res.match(
      (f) => showAppFeedback(context, f.message, type: FeedbackType.error),
      (_) => showAppFeedback(context, 'Justificativa enviada ao responsável.',
          type: FeedbackType.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(
        rosterStreamProvider((conexaoId: widget.conexaoId, data: _dataStr)));

    return Column(
      children: [
        _DayHeader(
          dia: _dia,
          ehHoje: _ehHoje,
          agora: _agora,
          onPrev: () => _mudarDia(-1),
          onNext: _ehHoje ? null : () => _mudarDia(1),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
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
                  onPressed: () => ref.invalidate(rosterStreamProvider(
                      (conexaoId: widget.conexaoId, data: _dataStr))),
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

/// Cabeçalho com navegação de dia e o relógio ao vivo (quando é hoje).
class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.dia,
    required this.ehHoje,
    required this.agora,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime dia;
  final bool ehHoje;
  final DateTime agora;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final dataFmt = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(dia);
    final dataCurta = DateFormat('dd/MM/yyyy').format(dia);
    final hora = DateFormat('HH:mm:ss').format(agora);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Dia anterior',
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(ehHoje ? Icons.today : Icons.event,
                        size: 18, color: AppColors.primaryAccessibleText),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ehHoje ? 'Hoje · $dataCurta' : _cap(dataFmt),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                // Relógio ao vivo só faz sentido para o dia atual.
                if (ehHoje)
                  Semantics(
                    liveRegion: true,
                    label: 'Hora atual $hora',
                    child: Text(hora,
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7))),
                  )
                else
                  Text('Chamada de $dataCurta',
                      style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Próximo dia',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
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
    final hora = item.presenca != null
        ? DateFormat('HH:mm').format(item.presenca!.horarioRegistro)
        : null;

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
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusTag(status: item.status),
                          if (item.origem != null) OriginTag(origem: item.origem!),
                          if (hora != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule,
                                    size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 3),
                                Text('às $hora',
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
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
