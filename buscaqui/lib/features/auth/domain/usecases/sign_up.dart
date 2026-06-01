import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUp implements UseCase<AppUser, SignUpParams> {
  const SignUp(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(SignUpParams p) {
    final nome = p.nome.trim();
    final email = p.email.trim();

    if (nome.length < 2) {
      return _fail('Informe seu nome completo.');
    }
    if (email.isEmpty || !email.contains('@')) {
      return _fail('Informe um e-mail válido.');
    }
    if (p.senha.length < 8) {
      return _fail('A senha deve ter pelo menos 8 caracteres.');
    }
    if (p.senha != p.confirmarSenha) {
      return _fail('As senhas não coincidem. Verifique e tente novamente.');
    }

    return _repository.signUpWithEmail(
      nome: nome,
      email: email,
      telefone: p.telefone.trim(),
      senha: p.senha,
      role: p.role,
    );
  }

  Future<Either<Failure, AppUser>> _fail(String msg) =>
      Future.value(Left(ValidationFailure(msg)));
}

class SignUpParams {
  const SignUpParams({
    required this.nome,
    required this.email,
    required this.telefone,
    required this.senha,
    required this.confirmarSenha,
    required this.role,
  });

  final String nome;
  final String email;
  final String telefone;
  final String senha;
  final String confirmarSenha;
  final UserRole role;
}
