import 'package:equatable/equatable.dart';

/// Posição da van num instante (espelha a tabela `localizacoes`).
class Localizacao extends Equatable {
  const Localizacao({
    required this.motoristaId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final String motoristaId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  @override
  List<Object?> get props => [motoristaId, latitude, longitude, timestamp];
}
