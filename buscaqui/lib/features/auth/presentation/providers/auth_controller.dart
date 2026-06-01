import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_up.dart';
import 'auth_provider.dart';

/// Controla as ações de autenticação (login/cadastro/reset) expondo
/// um `AsyncValue` que a UI observa para loading/erro/sucesso.
class AuthController extends AutoDisposeAsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async => null; // estado ocioso inicial

  Future<bool> signIn({required String email, required String senha}) async {
    state = const AsyncLoading();
    final result = await ref
        .read(signInProvider)
        .call(SignInParams(email: email, senha: senha));
    return result.match(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (user) {
        state = AsyncData(user);
        return true;
      },
    );
  }

  Future<bool> signUp(SignUpParams params) async {
    state = const AsyncLoading();
    final result = await ref.read(signUpProvider).call(params);
    return result.match(
      (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
      (user) {
        state = AsyncData(user);
        return true;
      },
    );
  }

  Future<String?> sendPasswordReset(String email) async {
    final result =
        await ref.read(authRepositoryProvider).sendPasswordReset(email);
    return result.match((f) => f.message, (_) => null);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
