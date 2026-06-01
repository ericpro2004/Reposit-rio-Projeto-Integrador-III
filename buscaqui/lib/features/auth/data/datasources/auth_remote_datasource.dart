import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';

/// Acesso direto ao Supabase Auth + tabela `usuarios`.
/// Lança exceções; a tradução para `Failure` ocorre no repositório.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<AppUserModel?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user);
  }

  Future<AppUserModel> signUp({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required UserRole role,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: senha,
      // O trigger handle_new_user lê estes metadados para criar o perfil.
      data: {'nome': nome, 'telefone': telefone, 'tipo_usuario': role.name},
    );
    final user = res.user;
    if (user == null) {
      throw const AuthException('Não foi possível concluir o cadastro.');
    }

    // GoTrue, por segurança, devolve um usuário "ofuscado" (sem identities)
    // quando o e-mail já está cadastrado — em vez de vazar essa informação.
    final identities = user.identities;
    if (identities != null && identities.isEmpty) {
      throw const AuthException(
        'Este e-mail já possui cadastro. Tente fazer login.',
      );
    }

    // Sem sessão = projeto exige confirmação de e-mail antes de entrar.
    if (res.session == null) {
      throw const AuthException(
        'Cadastro criado! Confirme seu e-mail para poder entrar.',
      );
    }

    return _fetchProfile(user);
  }

  Future<AppUserModel> signIn({
    required String email,
    required String senha,
  }) async {
    final res = await _client.auth
        .signInWithPassword(email: email, password: senha);
    final user = res.user;
    if (user == null) {
      throw const AuthException('Credenciais inválidas.');
    }
    return _fetchProfile(user);
  }

  Future<void> signInWithGoogle() =>
      _client.auth.signInWithOAuth(OAuthProvider.google);

  Future<void> signInWithApple() =>
      _client.auth.signInWithOAuth(OAuthProvider.apple);

  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email);

  Future<void> signOut() => _client.auth.signOut();

  Future<AppUserModel> _fetchProfile(User user) async {
    final row = await _client
        .from('usuarios')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row != null) return AppUserModel.fromMap(row);

    // Perfil ainda não existe (o trigger handle_new_user pode não ter rodado).
    // Cria a partir dos metadados do Auth — fallback resiliente.
    final model = AppUserModel(
      id: user.id,
      nome: user.userMetadata?['nome'] as String? ?? user.email ?? '',
      email: user.email ?? '',
      telefone: user.userMetadata?['telefone'] as String?,
      role: UserRole.fromString(
        user.userMetadata?['tipo_usuario'] as String? ?? 'passageiro',
      ),
    );
    try {
      await _client.from('usuarios').upsert(model.toMap());
    } catch (_) {
      // Best-effort: se falhar, seguimos com o perfil em memória.
    }
    return model;
  }
}
