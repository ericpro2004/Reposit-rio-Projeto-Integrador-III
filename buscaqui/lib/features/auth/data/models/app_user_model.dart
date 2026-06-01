import '../../domain/entities/app_user.dart';

/// Model de dados: converte a linha da tabela `usuarios` ⇄ entidade de domínio.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.nome,
    required super.email,
    required super.role,
    super.telefone,
    super.fotoUrl,
  });

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['id'] as String,
      nome: (map['nome'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: UserRole.fromString((map['tipo_usuario'] ?? 'passageiro') as String),
      telefone: map['telefone'] as String?,
      fotoUrl: map['foto_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'email': email,
        'tipo_usuario': role.name,
        'telefone': telefone,
        'foto_url': fotoUrl,
      };
}
