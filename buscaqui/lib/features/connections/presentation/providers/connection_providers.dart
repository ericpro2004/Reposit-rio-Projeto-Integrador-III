import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/connection_remote_datasource.dart';
import '../../data/repositories/connection_repository_impl.dart';
import '../../domain/entities/conexao.dart';
import '../../domain/repositories/connection_repository.dart';
import '../../domain/usecases/create_connection.dart';
import '../../domain/usecases/join_by_code.dart';

// ---- Injeção de dependências ----
final _dataSourceProvider = Provider<ConnectionRemoteDataSource>(
  (ref) => ConnectionRemoteDataSource(SupabaseConfig.client),
);

final connectionRepositoryProvider = Provider<ConnectionRepository>(
  (ref) => ConnectionRepositoryImpl(ref.watch(_dataSourceProvider)),
);

final _createConnectionProvider = Provider<CreateConnection>(
  (ref) => CreateConnection(ref.watch(connectionRepositoryProvider)),
);

final _joinByCodeProvider = Provider<JoinByCode>(
  (ref) => JoinByCode(ref.watch(connectionRepositoryProvider)),
);

/// Lista de conexões do usuário (Tela 5). Recarrega ao ser invalidado.
final myConnectionsProvider = FutureProvider<List<Conexao>>((ref) async {
  final result = await ref.watch(connectionRepositoryProvider).getMyConnections();
  return result.match((f) => throw f, (list) => list);
});

/// Controla ações de escrita (criar/entrar/atualizar token).
class ConnectionController extends AutoDisposeAsyncNotifier<Conexao?> {
  @override
  Future<Conexao?> build() async => null;

  Future<({Conexao? conexao, String? erro})> create(String nome) =>
      _run(() => ref.read(_createConnectionProvider).call(nome));

  Future<({Conexao? conexao, String? erro})> join(String codigo) =>
      _run(() => ref.read(_joinByCodeProvider).call(codigo));

  Future<({Conexao? conexao, String? erro})> refreshToken(String id) =>
      _run(() => ref.read(connectionRepositoryProvider).refreshToken(id));

  Future<({Conexao? conexao, String? erro})> _run(
    Future<Either<Failure, Conexao>> Function() action,
  ) async {
    state = const AsyncLoading();
    final result = await action();
    return result.match(
      (Failure f) {
        state = AsyncError(f, StackTrace.current);
        return (conexao: null, erro: f.message);
      },
      (Conexao c) {
        state = AsyncData(c);
        ref.invalidate(myConnectionsProvider); // atualiza a lista da Tela 5
        return (conexao: c, erro: null);
      },
    );
  }
}

final connectionControllerProvider =
    AutoDisposeAsyncNotifierProvider<ConnectionController, Conexao?>(
  ConnectionController.new,
);
