import '../../domain/entities/presenca.dart';

class PresencaModel extends Presenca {
  const PresencaModel({
    required super.id,
    required super.passageiroId,
    required super.status,
    required super.origem,
    required super.horarioRegistro,
    super.justificativa,
  });

  factory PresencaModel.fromMap(Map<String, dynamic> map) {
    return PresencaModel(
      id: map['id'] as String,
      passageiroId: map['passageiro_id'] as String,
      status: PresencaStatus.fromString((map['status'] ?? 'ausente') as String),
      origem: PresencaOrigem.fromString((map['origem'] ?? 'manual') as String),
      horarioRegistro:
          DateTime.tryParse(map['horario_registro']?.toString() ?? '') ??
              DateTime.now(),
      justificativa: map['justificativa'] as String?,
    );
  }
}
