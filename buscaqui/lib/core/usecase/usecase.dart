import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// Contrato base para todos os casos de uso da camada de domínio.
///
/// Retorna `Either<Failure, T>`: à esquerda o erro tratado, à direita o
/// sucesso. Mantém a regra de negócio independente de UI e de framework.
abstract interface class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use quando o caso de uso não recebe parâmetros.
class NoParams {
  const NoParams();
}
