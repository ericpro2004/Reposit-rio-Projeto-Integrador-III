import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/conexao.dart';
import '../repositories/connection_repository.dart';

class CreateConnection implements UseCase<Conexao, String> {
  const CreateConnection(this._repository);
  final ConnectionRepository _repository;

  @override
  Future<Either<Failure, Conexao>> call(String nomeConexao) {
    final nome = nomeConexao.trim();
    if (nome.length < 3) {
      return Future.value(
        const Left(ValidationFailure('Dê um nome com ao menos 3 caracteres.')),
      );
    }
    return _repository.createConnection(nome);
  }
}
