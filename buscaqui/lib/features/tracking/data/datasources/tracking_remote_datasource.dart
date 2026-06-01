import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/localizacao.dart';

class TrackingRemoteDataSource {
  TrackingRemoteDataSource(this._client);
  final SupabaseClient _client;

  /// Stream da última posição do motorista (Supabase Realtime).
  Stream<Localizacao?> watchLocation(String motoristaId) {
    return _client
        .from('localizacoes')
        .stream(primaryKey: ['id'])
        .eq('motorista_id', motoristaId)
        .order('timestamp', ascending: false)
        .limit(1)
        .map((rows) {
          if (rows.isEmpty) return null;
          final r = rows.first;
          return Localizacao(
            motoristaId: r['motorista_id'] as String,
            latitude: (r['latitude'] as num).toDouble(),
            longitude: (r['longitude'] as num).toDouble(),
            timestamp: DateTime.tryParse(r['timestamp']?.toString() ?? '') ??
                DateTime.now(),
          );
        });
  }

  Future<void> publishLocation({
    required double latitude,
    required double longitude,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('localizacoes').insert({
      'motorista_id': userId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}
