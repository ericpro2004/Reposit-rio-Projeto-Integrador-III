import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/attendance_stats.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/frequency_bar_chart.dart';

/// Tela 11 — Monitoramento (Dashboard). Indicadores consolidados e gráficos de
/// frequência semanal e mensal.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(attendanceStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Monitoramento')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(attendanceStatsProvider.future),
        child: statsAsync.when(
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
                  onPressed: () => ref.invalidate(attendanceStatsProvider),
                ),
              ),
            ],
          ),
          data: (stats) => _Content(stats: stats),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.stats});
  final AttendanceStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Indicadores
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Presenças',
                value: '${stats.totalPresentes}',
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Faltas',
                value: '${stats.totalAusentes}',
                icon: Icons.cancel,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Assiduidade',
          value: '${stats.assiduidade.toStringAsFixed(1)}%',
          icon: Icons.insights,
          color: AppColors.info,
          wide: true,
        ),
        const SizedBox(height: 24),
        _ChartSection(
          title: 'Frequência — últimos 7 dias',
          child: FrequencyBarChart(series: stats.dailySeries),
        ),
        const SizedBox(height: 24),
        _ChartSection(
          title: 'Frequência — últimas 4 semanas',
          child: FrequencyBarChart(series: stats.weeklySeries),
        ),
        const SizedBox(height: 16),
        const _Legend(),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(AppColors.success, 'Presentes'),
        const SizedBox(width: 24),
        _dot(AppColors.danger, 'Ausentes'),
      ],
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
