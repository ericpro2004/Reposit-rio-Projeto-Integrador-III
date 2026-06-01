import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/presenca.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._remote);
  final AttendanceRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<RosterItem>>> getRoster(String conexaoId) =>
      _guard(() => _remote.getRoster(conexaoId));

  @override
  Future<Either<Failure, Presenca>> markAttendance({
    required String passageiroId,
    required PresencaStatus status,
  }) =>
      _guard(() =>
          _remote.markAttendance(passageiroId: passageiroId, status: status));

  @override
  Future<Either<Failure, Presenca>> checkInByToken({
    required String token,
    required PresencaOrigem origem,
  }) =>
      _guard(() => _remote.checkInByToken(token: token, origem: origem));

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
