import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/conexao.dart';
import '../repositories/connection_repository.dart';

class JoinByCode implements UseCase<Conexao, String> {
  const JoinByCode(this._repository);
  final ConnectionRepository _repository;

  @override
  Future<Either<Failure, Conexao>> call(String codigo) {
    final code = codigo.trim().toUpperCase();
    if (code.length < 4) {
      return Future.value(
        const Left(ValidationFailure('Código inválido. Verifique e tente novamente.')),
      );
    }
    return _repository.joinByCode(code);
  }
}
