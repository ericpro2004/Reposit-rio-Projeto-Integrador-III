import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/attendance_stats.dart';

abstract interface class DashboardRepository {
  /// Consolida as presenças visíveis ao usuário (RLS por perfil) dos últimos
  /// ~30 dias em indicadores e séries para os gráficos.
  Future<Either<Failure, AttendanceStats>> getStats();
}
