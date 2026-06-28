import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/dashboard_providers.dart';

/// Tela 11 — Monitoramento. Conteúdo por papel:
/// - motorista: cada aluno de cada van;
/// - responsável: cada aluno (seus filhos);
/// - passageiro: o próprio.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(attendanceOverviewProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(attendanceOverviewProvider.future),
      child: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 120),
            const Center(child: Icon(Icons.error_outline, size: 48)),
            const SizedBox(height: 16),
            Center(
              child: AppButton(
                label: 'Tentar novamente',
                icon: Icons.refresh,
                expand: false,
                onPressed: () => ref.invalidate(attendanceOverviewProvider),
              ),
            ),
          ],
        ),
        data: (data) {
          final role = data['role'] as String?;
          return switch (role) {
            'motorista' => _MotoristaMonitor(vans: _list(data['vans'])),
            'responsavel' =>
              _AlunosMonitor(alunos: _list(data['alunos']), header: 'Seus alunos'),
            'passageiro' => _AlunosMonitor(
                alunos: _list(data['alunos']), header: 'Sua frequência'),
            _ => const _Empty(),
          };
        },
      ),
    );
  }

  static List<Map<String, dynamic>> _list(dynamic v) =>
      (v as List? ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
}

class _MotoristaMonitor extends StatelessWidget {
  const _MotoristaMonitor({required this.vans});
  final List<Map<String, dynamic>> vans;

  @override
  Widget build(BuildContext context) {
    if (vans.isEmpty) return const _Empty();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final van in vans) ...[
          _VanHeader(nome: van['conexao']?.toString() ?? 'Van'),
          for (final a in DashboardPage._list(van['alunos']))
            _AlunoStatCard(aluno: a),
          if (DashboardPage._list(van['alunos']).isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nenhum aluno nesta van ainda.'),
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AlunosMonitor extends StatelessWidget {
  const _AlunosMonitor({required this.alunos, required this.header});
  final List<Map<String, dynamic>> alunos;
  final String header;

  @override
  Widget build(BuildContext context) {
    if (alunos.isEmpty) return const _Empty();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(header, style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final a in alunos) _AlunoStatCard(aluno: a, showVan: true),
      ],
    );
  }
}

class _VanHeader extends StatelessWidget {
  const _VanHeader({required this.nome});
  final String nome;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          const Icon(Icons.directions_bus, color: AppColors.primaryAccessibleText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(nome, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}

class _AlunoStatCard extends StatelessWidget {
  const _AlunoStatCard({required this.aluno, this.showVan = false});
  final Map<String, dynamic> aluno;
  final bool showVan;

  int _n(String k) => (aluno[k] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final presentes = _n('presentes');
    final faltas = _n('faltas');
    final justificados = _n('justificados');
    final total = presentes + faltas + justificados;
    final assiduidade = total == 0 ? 0.0 : presentes / total;
    final pct = (assiduidade * 100).toStringAsFixed(0);

    final cor = assiduidade >= 0.75
        ? AppColors.success
        : (assiduidade >= 0.5 ? AppColors.warning : AppColors.danger);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(aluno['nome']?.toString() ?? 'Aluno',
                          style: Theme.of(context).textTheme.titleLarge),
                      if (showVan && aluno['van'] != null)
                        Text('Van: ${aluno['van']}',
                            style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                // % de assiduidade (texto + cor; nunca só cor).
                Semantics(
                  label: 'Assiduidade $pct por cento',
                  child: Text('$pct%',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: cor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : assiduidade,
                minHeight: 8,
                backgroundColor: AppColors.surface,
                color: cor,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(Icons.check_circle, AppColors.success, 'Presenças', presentes),
                _Chip(Icons.cancel, AppColors.danger, 'Faltas', faltas),
                _Chip(Icons.event_note, AppColors.warning, 'Justificadas',
                    justificados),
              ],
            ),
            if (total == 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Ainda sem registros de chamada.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.color, this.label, this.valor);
  final IconData icon;
  final Color color;
  final String label;
  final int valor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $valor',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text('$valor $label',
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.insights, size: 56),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Sem dados de monitoramento ainda.\n'
            'Os números aparecem conforme as chamadas são registradas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}
