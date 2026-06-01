import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_up.dart';

// ---- Injeção de dependências (data → domain) ----
final _dataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(SupabaseConfig.client),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(_dataSourceProvider)),
);

final signInProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);

final signUpProvider = Provider<SignUp>(
  (ref) => SignUp(ref.watch(authRepositoryProvider)),
);

/// Stream do estado de autenticação do Supabase (login, logout, refresh).
///
/// O `GoRouter` escuta este provider para redirecionar entre fluxo público
/// e área autenticada.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return SupabaseConfig.client.auth.onAuthStateChange;
});

/// Sessão atual derivada do stream (null = não autenticado).
final sessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull?.session ?? SupabaseConfig.session;
});

/// Conveniência booleana para guards de rota.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider) != null;
});
