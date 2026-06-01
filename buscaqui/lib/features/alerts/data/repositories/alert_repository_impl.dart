import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/alerta.dart';
import '../../domain/repositories/alert_repository.dart';
import '../datasources/alert_remote_datasource.dart';

class AlertRepositoryImpl implements AlertRepository {
  AlertRepositoryImpl(this._remote);
  final AlertRemoteDataSource _remote;

  @override
  Stream<List<Alerta>> watchAlerts() => _remote.watchAlerts();

  @override
  Future<Either<Failure, Unit>> markAsRead(String alertaId) async {
    try {
      await _remote.markAsRead(alertaId);
      return right(unit);
    } on PostgrestException catch (e) {
      return left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
