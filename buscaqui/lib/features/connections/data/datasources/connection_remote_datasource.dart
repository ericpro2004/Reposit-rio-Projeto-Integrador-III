import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conexao_model.dart';

/// Acesso ao Supabase para a feature de conexões.
class ConnectionRemoteDataSource {
  ConnectionRemoteDataSource(this._client);
  final SupabaseClient _client;

  /// Lista conexões visíveis ao usuário (RLS aplica o filtro por perfil),
  /// incluindo a contagem de passageiros.
  Future<List<ConexaoModel>> getMyConnections() async {
    final rows = await _client
        .from('conexoes')
        .select('*, passageiros(count)')
        .order('criado_em', ascending: false);
    return rows.map(ConexaoModel.fromMap).toList();
  }

  Future<ConexaoModel> createConnection(String nomeConexao) async {
    final userId = _client.auth.currentUser!.id;
    // codigo/qrcode_data ficam a cargo do trigger gen_connection_code.
    final row = await _client
        .from('conexoes')
        .insert({'nome_conexao': nomeConexao, 'motorista_id': userId})
        .select()
        .single();
    return ConexaoModel.fromMap(row);
  }

  Future<ConexaoModel> joinByCode(String codigo) async {
    final data = await _client.rpc(
      'join_connection',
      params: {'p_codigo': codigo},
    );
    return ConexaoModel.fromMap(_asMap(data));
  }

  Future<ConexaoModel> refreshToken(String conexaoId) async {
    final data = await _client.rpc(
      'refresh_connection_token',
      params: {'p_id': conexaoId},
    );
    return ConexaoModel.fromMap(_asMap(data));
  }

  /// RPCs que retornam um tipo de tabela podem vir como Map ou como List<Map>
  /// de um único elemento, dependendo da versão do PostgREST.
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is List) return data.first as Map<String, dynamic>;
    return data as Map<String, dynamic>;
  }
}
