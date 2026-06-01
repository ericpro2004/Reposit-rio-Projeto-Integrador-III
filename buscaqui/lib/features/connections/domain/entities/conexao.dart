import 'package:equatable/equatable.dart';

/// Conexão = uma rota/van criada por um motorista. Entidade pura de domínio.
class Conexao extends Equatable {
  const Conexao({
    required this.id,
    required this.nomeConexao,
    required this.codigo,
    required this.qrCodeData,
    required this.motoristaId,
    required this.criadoEm,
    this.totalPassageiros = 0,
  });

  final String id;
  final String nomeConexao;
  final String codigo;
  final String qrCodeData;
  final String motoristaId;
  final DateTime criadoEm;

  /// Quantidade de passageiros vinculados (preenchido quando disponível).
  final int totalPassageiros;

  @override
  List<Object?> get props =>
      [id, nomeConexao, codigo, qrCodeData, motoristaId, criadoEm];
}
