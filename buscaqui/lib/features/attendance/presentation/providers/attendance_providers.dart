import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/presenca.dart';
import '../../domain/repositories/attendance_repository.dart';

// ---- Injeção de dependências ----
final _dataSourceProvider = Provider<AttendanceRemoteDataSource>(
  (ref) => AttendanceRemoteDataSource(SupabaseConfig.client),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(ref.watch(_dataSourceProvider)),
);

/// Roster em tempo real de uma conexão (chamada do motorista). Atualiza
/// automaticamente quando um aluno faz check-in por QR ou na marcação manual.
final rosterStreamProvider =
    StreamProvider.autoDispose.family<List<RosterItem>, String>(
  (ref, conexaoId) =>
      ref.watch(attendanceRepositoryProvider).watchRoster(conexaoId),
);

/// Lista de chamada por conexão (Tela 9). Mantém o estado e aplica atualização
/// otimista ao marcar presença/ausência.
class RosterController
    extends AutoDisposeFamilyAsyncNotifier<List<RosterItem>, String> {
  @override
  Future<List<RosterItem>> build(String conexaoId) async {
    final res = await ref.watch(attendanceRepositoryProvider).getRoster(conexaoId);
    return res.match((f) => throw f, (list) => list);
  }

  /// Retorna null em sucesso, ou a mensagem de erro.
  Future<String?> mark(String passageiroId, PresencaStatus status) async {
    final res = await ref
        .read(attendanceRepositoryProvider)
        .markAttendance(passageiroId: passageiroId, status: status);
    return res.match(
      (f) => f.message,
      (presenca) {
        final current = state.valueOrNull ?? const <RosterItem>[];
        state = AsyncData([
          for (final item in current)
            if (item.passageiroId == passageiroId)
              item.copyWith(presenca: presenca)
            else
              item,
        ]);
        return null;
      },
    );
  }
}

final rosterControllerProvider = AutoDisposeAsyncNotifierProviderFamily<
    RosterController, List<RosterItem>, String>(RosterController.new);

/// Controller do check-in por QR/código (Tela 8).
class CheckInController extends AutoDisposeAsyncNotifier<Presenca?> {
  @override
  Future<Presenca?> build() async => null;

  Future<({Presenca? presenca, String? erro})> checkIn({
    required String token,
    required PresencaOrigem origem,
  }) async {
    state = const AsyncLoading();
    final res = await ref
        .read(attendanceRepositoryProvider)
        .checkInByToken(token: token, origem: origem);
    return res.match(
      (f) {
        state = AsyncError(f, StackTrace.current);
        return (presenca: null, erro: f.message);
      },
      (p) {
        state = AsyncData(p);
        return (presenca: p, erro: null);
      },
    );
  }
}

final checkInControllerProvider =
    AutoDisposeAsyncNotifierProvider<CheckInController, Presenca?>(
  CheckInController.new,
);
