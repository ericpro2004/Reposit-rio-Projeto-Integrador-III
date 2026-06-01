import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/conexao.dart';
import '../../domain/repositories/connection_repository.dart';
import '../datasources/connection_remote_datasource.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  ConnectionRepositoryImpl(this._remote);
  final ConnectionRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Conexao>>> getMyConnections() =>
      _guard(() => _remote.getMyConnections());

  @override
  Future<Either<Failure, Conexao>> createConnection(String nomeConexao) =>
      _guard(() => _remote.createConnection(nomeConexao));

  @override
  Future<Either<Failure, Conexao>> joinByCode(String codigo) =>
      _guard(() => _remote.joinByCode(codigo));

  @override
  Future<Either<Failure, Conexao>> refreshToken(String conexaoId) =>
      _guard(() => _remote.refreshToken(conexaoId));

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on PostgrestException catch (e) {
      // Mensagens das RPCs (raise exception) chegam aqui já em PT-BR.
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
