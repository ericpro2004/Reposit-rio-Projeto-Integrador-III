import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/alerta_model.dart';

class AlertRemoteDataSource {
  AlertRemoteDataSource(this._client);
  final SupabaseClient _client;

  /// Stream em tempo real (Supabase Realtime). O RLS já filtra por usuário.
  Stream<List<AlertaModel>> watchAlerts() {
    return _client
        .from('alertas')
        .stream(primaryKey: ['id'])
        .order('criado_em', ascending: false)
        .map((rows) => rows.map(AlertaModel.fromMap).toList());
  }

  Future<void> markAsRead(String alertaId) async {
    await _client.from('alertas').update({'lido': true}).eq('id', alertaId);
  }
}
