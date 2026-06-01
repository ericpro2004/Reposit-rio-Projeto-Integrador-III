import 'package:equatable/equatable.dart';

/// Perfis do sistema (espelha o enum `tipo_usuario` no Postgres).
enum UserRole {
  motorista,
  responsavel,
  passageiro;

  static UserRole fromString(String value) => UserRole.values.firstWhere(
        (r) => r.name == value,
        orElse: () => UserRole.passageiro,
      );

  String get label => switch (this) {
        UserRole.motorista => 'Motorista',
        UserRole.responsavel => 'Responsável',
        UserRole.passageiro => 'Passageiro / Aluno',
      };
}

/// Entidade de domínio do usuário autenticado. Puro Dart — sem Supabase.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    this.telefone,
    this.fotoUrl,
  });

  final String id;
  final String nome;
  final String email;
  final UserRole role;
  final String? telefone;
  final String? fotoUrl;

  @override
  List<Object?> get props => [id, nome, email, role, telefone, fotoUrl];
}
