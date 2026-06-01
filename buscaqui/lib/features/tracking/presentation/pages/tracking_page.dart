import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../connections/domain/entities/conexao.dart';
import '../../domain/entities/localizacao.dart';
import '../providers/tracking_providers.dart';

/// Tela de Monitoramento ao vivo: acompanha a posição da van no mapa em tempo
/// real. Para o motorista da conexão, permite iniciar/parar o compartilhamento.
class TrackingPage extends ConsumerStatefulWidget {
  const TrackingPage({super.key, required this.conexao});
  final Conexao conexao;

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  final _mapController = Completer<GoogleMapController>();

  // Posição inicial (fallback) — centro aproximado do Brasil.
  static const _fallback = CameraPosition(target: LatLng(-15.78, -47.92), zoom: 4);

  bool get _isMotorista =>
      SupabaseConfig.currentUser?.id == widget.conexao.motoristaId;

  Future<void> _moveCamera(Localizacao loc) async {
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(loc.latitude, loc.longitude), 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(vanLocationProvider(widget.conexao.motoristaId));

    // Move a câmera sempre que chega uma nova posição.
    ref.listen(vanLocationProvider(widget.conexao.motoristaId), (_, next) {
      final loc = next.valueOrNull;
      if (loc != null) _moveCamera(loc);
    });

    final loc = locationAsync.valueOrNull;
    final markers = <Marker>{
      if (loc != null)
        Marker(
          markerId: const MarkerId('van'),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(title: widget.conexao.nomeConexao),
        ),
    };

    return Scaffold(
      appBar: AppBar(title: Text('Localização — ${widget.conexao.nomeConexao}')),
      floatingActionButton: _isMotorista ? const _ShareLocationFab() : null,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _fallback,
            markers: markers,
            myLocationEnabled: _isMotorista,
            myLocationButtonEnabled: false,
            onMapCreated: (c) {
              if (!_mapController.isCompleted) _mapController.complete(c);
            },
          ),
          // Faixa de status acessível no topo.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _StatusBanner(
              loading: locationAsync.isLoading,
              hasLocation: loc != null,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.loading, required this.hasLocation});
  final bool loading;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    final text = loading
        ? 'Conectando ao monitoramento…'
        : hasLocation
            ? 'Acompanhando a van em tempo real.'
            : 'Aguardando a van iniciar o compartilhamento.';
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                hasLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: hasLocation ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão do motorista para iniciar/parar o envio da localização.
class _ShareLocationFab extends ConsumerWidget {
  const _ShareLocationFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationSharingProvider);
    final notifier = ref.read(locationSharingProvider.notifier);

    // Exibe erro de permissão/serviço quando ocorre.
    ref.listen(locationSharingProvider, (_, next) {
      if (next is SharingError) {
        showAppFeedback(context, next.message, type: FeedbackType.error);
      }
    });

    final isOn = state is SharingOn;
    return FloatingActionButton.extended(
      backgroundColor: isOn ? AppColors.danger : null,
      onPressed: () => isOn ? notifier.stop() : notifier.start(),
      icon: Icon(isOn ? Icons.stop : Icons.share_location),
      label: Text(isOn ? 'Parar' : 'Compartilhar localização'),
    );
  }
}
