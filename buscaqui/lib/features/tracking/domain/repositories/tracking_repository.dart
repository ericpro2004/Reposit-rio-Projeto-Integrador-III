import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/localizacao.dart';

abstract interface class TrackingRepository {
  /// Acompanha em tempo real a última posição da van de um motorista.
  Stream<Localizacao?> watchLocation(String motoristaId);

  /// Motorista publica a posição atual (chamado periodicamente em background).
  Future<Either<Failure, Unit>> publishLocation({
    required double latitude,
    required double longitude,
  });
}
