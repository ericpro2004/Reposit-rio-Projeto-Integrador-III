import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../data/datasources/alert_remote_datasource.dart';
import '../../data/repositories/alert_repository_impl.dart';
import '../../domain/entities/alerta.dart';
import '../../domain/repositories/alert_repository.dart';

final _dataSourceProvider = Provider<AlertRemoteDataSource>(
  (ref) => AlertRemoteDataSource(SupabaseConfig.client),
);

final alertRepositoryProvider = Provider<AlertRepository>(
  (ref) => AlertRepositoryImpl(ref.watch(_dataSourceProvider)),
);

/// Feed de alertas em tempo real (Tela 10).
final alertsStreamProvider = StreamProvider<List<Alerta>>(
  (ref) => ref.watch(alertRepositoryProvider).watchAlerts(),
);

/// Quantidade de alertas não lidos (para badge/indicadores).
final unreadAlertsCountProvider = Provider<int>((ref) {
  return ref.watch(alertsStreamProvider).maybeWhen(
        data: (list) => list.where((a) => !a.lido).length,
        orElse: () => 0,
      );
});
