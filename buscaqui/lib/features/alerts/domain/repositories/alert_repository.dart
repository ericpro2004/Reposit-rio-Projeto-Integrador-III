import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/alerta.dart';

abstract interface class AlertRepository {
  /// Stream em tempo real dos alertas visíveis ao usuário (Supabase Realtime).
  Stream<List<Alerta>> watchAlerts();

  /// Marca um alerta como lido.
  Future<Either<Failure, Unit>> markAsRead(String alertaId);
}
