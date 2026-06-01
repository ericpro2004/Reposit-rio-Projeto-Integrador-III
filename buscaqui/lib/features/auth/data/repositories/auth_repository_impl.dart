import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementa o contrato de domínio traduzindo exceções do Supabase em
/// [Failure]s com mensagens claras (acessibilidade: compreensível).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Future<Either<Failure, AppUser?>> currentUser() =>
      _guard(() => _remote.currentUser());

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required UserRole role,
  }) =>
      _guard(() => _remote.signUp(
            nome: nome,
            email: email,
            telefone: telefone,
            senha: senha,
            role: role,
          ));

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String senha,
  }) =>
      _guard(() => _remote.signIn(email: email, senha: senha));

  @override
  Future<Either<Failure, Unit>> signInWithGoogle() =>
      _guardUnit(_remote.signInWithGoogle);

  @override
  Future<Either<Failure, Unit>> signInWithApple() =>
      _guardUnit(_remote.signInWithApple);

  @override
  Future<Either<Failure, Unit>> sendPasswordReset(String email) =>
      _guardUnit(() => _remote.sendPasswordReset(email));

  @override
  Future<Either<Failure, Unit>> signOut() => _guardUnit(_remote.signOut);

  // ---- helpers de tratamento de erro ----
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(AuthFailure(_humanize(e.message)));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  Future<Either<Failure, Unit>> _guardUnit(Future<void> Function() action) =>
      _guard(() async {
        await action();
        return unit;
      });

  String _humanize(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('invalid login')) {
      return 'E-mail ou senha incorretos.';
    }
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'Este e-mail já possui cadastro. Tente fazer login.';
    }
    if (m.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    return raw;
  }
}
