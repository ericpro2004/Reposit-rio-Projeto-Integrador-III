import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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

/// Indicadores consolidados (gráficos da Tela 11).
final attendanceStatsProvider = FutureProvider<AttendanceStats>((ref) async {
  final result = await ref.watch(dashboardRepositoryProvider).getStats();
  return result.match((f) => throw f, (stats) => stats);
});

/// Monitoramento por papel (motorista/responsável/passageiro), via RPC
/// `attendance_overview`. Recarrega ao mudar a autenticação.
final attendanceOverviewProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(authStateChangesProvider);
  final data = await SupabaseConfig.client.rpc('attendance_overview');
  return (data as Map).cast<String, dynamic>();
});
