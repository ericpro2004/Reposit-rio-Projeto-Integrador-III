import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/attendance_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

final _dataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSource(SupabaseConfig.client),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(ref.watch(_dataSourceProvider)),
);

/// Indicadores consolidados (Tela 11).
final attendanceStatsProvider = FutureProvider<AttendanceStats>((ref) async {
  final result = await ref.watch(dashboardRepositoryProvider).getStats();
  return result.match((f) => throw f, (stats) => stats);
});
