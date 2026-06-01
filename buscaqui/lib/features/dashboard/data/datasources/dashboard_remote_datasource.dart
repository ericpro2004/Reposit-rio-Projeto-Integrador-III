import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._client);
  final SupabaseClient _client;

  /// Presenças visíveis (RLS por perfil) desde [since] (yyyy-MM-dd).
  /// Retorna apenas os campos necessários para os agregados.
  Future<List<Map<String, dynamic>>> recentPresencas(String since) async {
    final rows = await _client
        .from('presencas')
        .select('data, status')
        .gte('data', since);
    return rows;
  }
}
