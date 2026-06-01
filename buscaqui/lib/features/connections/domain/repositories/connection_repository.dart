import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/conexao.dart';

/// Contrato de acesso a conexões. Implementação em `data/` (Supabase).
abstract interface class ConnectionRepository {
  /// Conexões visíveis ao usuário atual (próprias, se motorista; ou as dos
  /// passageiros vinculados, se responsável/passageiro).
  Future<Either<Failure, List<Conexao>>> getMyConnections();

  /// Motorista cria uma nova conexão; código e QR são gerados pelo backend.
  Future<Either<Failure, Conexao>> createConnection(String nomeConexao);

  /// Passageiro entra em uma conexão informando o código alfanumérico.
  Future<Either<Failure, Conexao>> joinByCode(String codigo);

  /// Motorista regenera o token/código da conexão (invalida o anterior).
  Future<Either<Failure, Conexao>> refreshToken(String conexaoId);
}
