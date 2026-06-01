import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/attendance_stats.dart';

/// Gráfico de barras agrupadas (presentes x ausentes) por período.
/// Acessível: acompanhado de um resumo textual (`Semantics`) já que gráficos
/// puramente visuais não são lidos por leitores de tela.
class FrequencyBarChart extends StatelessWidget {
  const FrequencyBarChart({super.key, required this.series});
  final List<PeriodSummary> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Sem dados no período.')),
      );
    }

    final maxY = series
        .map((s) => s.total == 0 ? 1 : s.total)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final textSummary = series
        .map((s) => '${s.label}: ${s.presentes} presentes, ${s.ausentes} ausentes')
        .join('. ');

    return Semantics(
      label: 'Gráfico de frequência. $textSummary',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY + 1,
              barTouchData: BarTouchData(enabled: true),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= series.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          series[i].label,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < series.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: series[i].presentes.toDouble(),
                        color: AppColors.success,
                        width: 10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: series[i].ausentes.toDouble(),
                        color: AppColors.danger,
                        width: 10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
