import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/localizacao.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_remote_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl(this._remote);
  final TrackingRemoteDataSource _remote;

  @override
  Stream<Localizacao?> watchLocation(String motoristaId) =>
      _remote.watchLocation(motoristaId);

  @override
  Future<Either<Failure, Unit>> publishLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _remote.publishLocation(latitude: latitude, longitude: longitude);
      return right(unit);
    } on PostgrestException catch (e) {
      return left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
