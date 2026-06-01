import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/config/supabase_config.dart';
import '../../data/datasources/tracking_remote_datasource.dart';
import '../../data/repositories/tracking_repository_impl.dart';
import '../../domain/entities/localizacao.dart';
import '../../domain/repositories/tracking_repository.dart';

final _dataSourceProvider = Provider<TrackingRemoteDataSource>(
  (ref) => TrackingRemoteDataSource(SupabaseConfig.client),
);

final trackingRepositoryProvider = Provider<TrackingRepository>(
  (ref) => TrackingRepositoryImpl(ref.watch(_dataSourceProvider)),
);

/// Última posição da van de um motorista, em tempo real (Tela de mapa).
final vanLocationProvider =
    StreamProvider.autoDispose.family<Localizacao?, String>(
  (ref, motoristaId) =>
      ref.watch(trackingRepositoryProvider).watchLocation(motoristaId),
);

/// Estado do compartilhamento de localização (visão motorista).
sealed class SharingState {}

class SharingOff extends SharingState {}

class SharingOn extends SharingState {}

class SharingError extends SharingState {
  SharingError(this.message);
  final String message;
}

/// Controla o envio periódico da posição do motorista ao Supabase usando o GPS.
class LocationSharingController extends AutoDisposeNotifier<SharingState> {
  StreamSubscription<Position>? _sub;

  @override
  SharingState build() {
    ref.onDispose(() => _sub?.cancel());
    return SharingOff();
  }

  Future<void> start() async {
    // Verifica serviço e permissões antes de iniciar.
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      state = SharingError('Ative a localização do dispositivo para compartilhar.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = SharingError('Permissão de localização negada.');
      return;
    }

    final repo = ref.read(trackingRepositoryProvider);
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15, // metros entre atualizações
      ),
    ).listen((pos) {
      repo.publishLocation(latitude: pos.latitude, longitude: pos.longitude);
    });
    state = SharingOn();
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    state = SharingOff();
  }
}

final locationSharingProvider =
    AutoDisposeNotifierProvider<LocationSharingController, SharingState>(
  LocationSharingController.new,
);
