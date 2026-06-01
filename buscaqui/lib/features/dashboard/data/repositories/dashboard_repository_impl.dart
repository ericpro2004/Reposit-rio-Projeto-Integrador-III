import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/attendance_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remote);
  final DashboardRemoteDataSource _remote;

  @override
  Future<Either<Failure, AttendanceStats>> getStats() async {
    try {
      final today = DateTime.now();
      final start = _dateOnly(today).subtract(const Duration(days: 27));
      final since = DateFormat('yyyy-MM-dd').format(start);

      final rows = await _remote.recentPresencas(since);
      return Right(_aggregate(rows, today));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  AttendanceStats _aggregate(List<Map<String, dynamic>> rows, DateTime today) {
    final t0 = _dateOnly(today);
    var presentes = 0, ausentes = 0, justificados = 0;

    // Buckets diários (0 = hoje .. 6) e semanais (0 = esta semana .. 3).
    final dailyP = List.filled(7, 0), dailyA = List.filled(7, 0);
    final weeklyP = List.filled(4, 0), weeklyA = List.filled(4, 0);

    for (final row in rows) {
      final status = (row['status'] ?? '') as String;
      final data = DateTime.tryParse((row['data'] ?? '').toString());
      if (data == null) continue;
      final daysAgo = t0.difference(_dateOnly(data)).inDays;

      switch (status) {
        case 'presente':
          presentes++;
        case 'ausente':
          ausentes++;
        case 'justificado':
          justificados++;
      }

      final isPresente = status == 'presente';
      if (daysAgo >= 0 && daysAgo < 7) {
        if (isPresente) {
          dailyP[daysAgo]++;
        } else if (status == 'ausente') {
          dailyA[daysAgo]++;
        }
      }
      if (daysAgo >= 0 && daysAgo < 28) {
        final w = daysAgo ~/ 7;
        if (isPresente) {
          weeklyP[w]++;
        } else if (status == 'ausente') {
          weeklyA[w]++;
        }
      }
    }

    final weekdayFmt = DateFormat('E', 'pt_BR'); // seg, ter, ...
    final daily = <PeriodSummary>[];
    for (var i = 6; i >= 0; i--) {
      final day = t0.subtract(Duration(days: i));
      daily.add(PeriodSummary(
        label: weekdayFmt.format(day),
        presentes: dailyP[i],
        ausentes: dailyA[i],
      ));
    }

    const weekLabels = ['Há 3 sem', 'Há 2 sem', 'Sem. passada', 'Esta sem.'];
    final weekly = <PeriodSummary>[];
    for (var i = 3; i >= 0; i--) {
      weekly.add(PeriodSummary(
        label: weekLabels[3 - i],
        presentes: weeklyP[i],
        ausentes: weeklyA[i],
      ));
    }

    return AttendanceStats(
      totalPresentes: presentes,
      totalAusentes: ausentes,
      totalJustificados: justificados,
      dailySeries: daily,
      weeklySeries: weekly,
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
