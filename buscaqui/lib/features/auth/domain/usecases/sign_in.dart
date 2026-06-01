import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignIn implements UseCase<AppUser, SignInParams> {
  const SignIn(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, AppUser>> call(SignInParams params) {
    final email = params.email.trim();
    if (email.isEmpty || !email.contains('@')) {
      return Future.value(
        const Left(ValidationFailure('Informe um e-mail válido.')),
      );
    }
    if (params.senha.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Informe sua senha.')),
      );
    }
    return _repository.signInWithEmail(email: email, senha: params.senha);
  }
}

class SignInParams {
  const SignInParams({required this.email, required this.senha});
  final String email;
  final String senha;
}
