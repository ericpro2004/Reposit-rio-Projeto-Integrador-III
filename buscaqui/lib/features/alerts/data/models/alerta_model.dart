import '../../domain/entities/alerta.dart';

class AlertaModel extends Alerta {
  const AlertaModel({
    required super.id,
    required super.passageiroId,
    required super.mensagem,
    required super.lido,
    required super.criadoEm,
  });

  factory AlertaModel.fromMap(Map<String, dynamic> map) {
    return AlertaModel(
      id: map['id'] as String,
      passageiroId: (map['passageiro_id'] ?? '') as String,
      mensagem: (map['mensagem'] ?? '') as String,
      lido: (map['lido'] ?? false) as bool,
      criadoEm: DateTime.tryParse(map['criado_em']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
