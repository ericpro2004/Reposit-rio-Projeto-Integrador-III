import '../../domain/entities/conexao.dart';

/// Converte linha da tabela `conexoes` ⇄ entidade [Conexao].
class ConexaoModel extends Conexao {
  const ConexaoModel({
    required super.id,
    required super.nomeConexao,
    required super.codigo,
    required super.qrCodeData,
    required super.motoristaId,
    required super.criadoEm,
    super.totalPassageiros,
  });

  factory ConexaoModel.fromMap(Map<String, dynamic> map) {
    // `passageiros` pode vir como agregação de contagem do PostgREST.
    int total = 0;
    final pass = map['passageiros'];
    if (pass is List && pass.isNotEmpty && pass.first is Map) {
      total = (pass.first['count'] as int?) ?? 0;
    }

    return ConexaoModel(
      id: map['id'] as String,
      nomeConexao: (map['nome_conexao'] ?? '') as String,
      codigo: (map['codigo'] ?? '') as String,
      qrCodeData: (map['qrcode_data'] ?? '') as String,
      motoristaId: (map['motorista_id'] ?? '') as String,
      criadoEm: DateTime.tryParse(map['criado_em']?.toString() ?? '') ??
          DateTime.now(),
      totalPassageiros: total,
    );
  }
}
