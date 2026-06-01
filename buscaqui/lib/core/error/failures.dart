import 'package:equatable/equatable.dart';

/// Falhas tratadas na camada de domínio/apresentação.
/// Mensagens são em PT-BR e descritivas (acessibilidade: compreensível).
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Falha ao comunicar com o servidor.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Não foi possível autenticar.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
