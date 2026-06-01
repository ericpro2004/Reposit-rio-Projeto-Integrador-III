import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/presenca.dart';

abstract interface class AttendanceRepository {
  /// Lista de chamada (passageiros + presença de hoje) de uma conexão.
  Future<Either<Failure, List<RosterItem>>> getRoster(String conexaoId);

  /// Motorista marca manualmente a presença de um passageiro.
  Future<Either<Failure, Presenca>> markAttendance({
    required String passageiroId,
    required PresencaStatus status,
  });

  /// Check-in do próprio passageiro via QR ou código (origem registrada).
  Future<Either<Failure, Presenca>> checkInByToken({
    required String token,
    required PresencaOrigem origem,
  });
}
