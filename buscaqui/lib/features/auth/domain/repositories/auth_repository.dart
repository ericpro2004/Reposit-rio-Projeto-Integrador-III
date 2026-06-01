import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

/// Contrato de autenticação. A implementação fica em `data/` (Supabase),
/// mantendo o domínio independente do backend.
abstract interface class AuthRepository {
  /// Usuário atualmente logado, ou null.
  Future<Either<Failure, AppUser?>> currentUser();

  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required UserRole role,
  });

  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String senha,
  });

  /// OAuth nativo (Google/Apple) via Supabase.
  Future<Either<Failure, Unit>> signInWithGoogle();
  Future<Either<Failure, Unit>> signInWithApple();

  Future<Either<Failure, Unit>> sendPasswordReset(String email);

  Future<Either<Failure, Unit>> signOut();
}
