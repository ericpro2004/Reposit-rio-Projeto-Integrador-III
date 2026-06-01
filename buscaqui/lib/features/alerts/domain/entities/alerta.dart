import 'package:equatable/equatable.dart';

/// Alerta enviado ao responsável (espelha a tabela `alertas`).
class Alerta extends Equatable {
  const Alerta({
    required this.id,
    required this.passageiroId,
    required this.mensagem,
    required this.lido,
    required this.criadoEm,
  });

  final String id;
  final String passageiroId;
  final String mensagem;
  final bool lido;
  final DateTime criadoEm;

  Alerta copyWith({bool? lido}) => Alerta(
        id: id,
        passageiroId: passageiroId,
        mensagem: mensagem,
        lido: lido ?? this.lido,
        criadoEm: criadoEm,
      );

  @override
  List<Object?> get props => [id, passageiroId, mensagem, lido, criadoEm];
}
