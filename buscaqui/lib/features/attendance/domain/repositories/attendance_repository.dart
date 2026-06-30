import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/presenca.dart';

abstract interface class AttendanceRepository {
  /// Lista de chamada (passageiros + presença de hoje) de uma conexão.
  Future<Either<Failure, List<RosterItem>>> getRoster(String conexaoId);

  /// Stream em tempo real do roster de uma data (atualiza a cada check-in).
  Stream<List<RosterItem>> watchRoster(String conexaoId, String data);

  /// Motorista marca manualmente a presença de um passageiro (data opcional).
  Future<Either<Failure, Presenca>> markAttendance({
    required String passageiroId,
    required PresencaStatus status,
    String? data,
  });

  /// Motorista registra/edita a justificativa (enviada ao responsável).
  Future<Either<Failure, Presenca>> setJustificativa({
    required String passageiroId,
    required String justificativa,
    String? data,
  });

  /// Check-in do próprio passageiro via QR ou código (origem registrada).
  Future<Either<Failure, Presenca>> checkInByToken({
    required String token,
    required PresencaOrigem origem,
  });
}
