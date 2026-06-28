import 'package:equatable/equatable.dart';

/// Status da presença (espelha o enum `presenca_status`).
enum PresencaStatus {
  presente,
  ausente,
  justificado;

  static PresencaStatus fromString(String v) => PresencaStatus.values
      .firstWhere((e) => e.name == v, orElse: () => PresencaStatus.ausente);

  String get label => switch (this) {
        PresencaStatus.presente => 'Presente',
        PresencaStatus.ausente => 'Ausente',
        PresencaStatus.justificado => 'Justificado',
      };
}

/// Origem do registro (espelha o enum `presenca_origem`).
enum PresencaOrigem {
  manual,
  qrcode,
  codigo;

  static PresencaOrigem fromString(String v) => PresencaOrigem.values
      .firstWhere((e) => e.name == v, orElse: () => PresencaOrigem.manual);

  String get label => switch (this) {
        PresencaOrigem.manual => 'Manual',
        PresencaOrigem.qrcode => 'QR Code',
        PresencaOrigem.codigo => 'Código',
      };
}

/// Registro de presença de um passageiro em uma data.
class Presenca extends Equatable {
  const Presenca({
    required this.id,
    required this.passageiroId,
    required this.status,
    required this.origem,
    required this.horarioRegistro,
    this.justificativa,
  });

  final String id;
  final String passageiroId;
  final PresencaStatus status;
  final PresencaOrigem origem;
  final DateTime horarioRegistro;
  final String? justificativa;

  @override
  List<Object?> get props =>
      [id, passageiroId, status, origem, horarioRegistro, justificativa];
}

/// Item da lista de chamada: passageiro + (opcional) presença de hoje.
class RosterItem extends Equatable {
  const RosterItem({
    required this.passageiroId,
    required this.nome,
    this.fotoUrl,
    this.presenca,
  });

  final String passageiroId;
  final String nome;
  final String? fotoUrl;
  final Presenca? presenca;

  PresencaStatus? get status => presenca?.status;
  PresencaOrigem? get origem => presenca?.origem;
  String? get justificativa => presenca?.justificativa;

  RosterItem copyWith({Presenca? presenca}) => RosterItem(
        passageiroId: passageiroId,
        nome: nome,
        fotoUrl: fotoUrl,
        presenca: presenca ?? this.presenca,
      );

  @override
  List<Object?> get props => [passageiroId, nome, fotoUrl, presenca];
}
