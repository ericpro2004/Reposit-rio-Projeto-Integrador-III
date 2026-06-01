import 'package:equatable/equatable.dart';

/// Resumo de um período (um dia ou uma semana) para os gráficos.
class PeriodSummary extends Equatable {
  const PeriodSummary({
    required this.label,
    required this.presentes,
    required this.ausentes,
  });

  final String label;
  final int presentes;
  final int ausentes;

  int get total => presentes + ausentes;

  @override
  List<Object?> get props => [label, presentes, ausentes];
}

/// Indicadores consolidados de assiduidade (Tela 11).
class AttendanceStats extends Equatable {
  const AttendanceStats({
    required this.totalPresentes,
    required this.totalAusentes,
    required this.totalJustificados,
    required this.dailySeries,
    required this.weeklySeries,
  });

  final int totalPresentes;
  final int totalAusentes;
  final int totalJustificados;

  /// Frequência diária (últimos 7 dias).
  final List<PeriodSummary> dailySeries;

  /// Frequência semanal (últimas 4 semanas).
  final List<PeriodSummary> weeklySeries;

  int get totalRegistros => totalPresentes + totalAusentes + totalJustificados;

  /// Percentual de assiduidade: presentes sobre o total de registros.
  double get assiduidade {
    if (totalRegistros == 0) return 0;
    return (totalPresentes / totalRegistros) * 100;
  }

  static const empty = AttendanceStats(
    totalPresentes: 0,
    totalAusentes: 0,
    totalJustificados: 0,
    dailySeries: [],
    weeklySeries: [],
  );

  @override
  List<Object?> get props => [
        totalPresentes,
        totalAusentes,
        totalJustificados,
        dailySeries,
        weeklySeries,
      ];
}
