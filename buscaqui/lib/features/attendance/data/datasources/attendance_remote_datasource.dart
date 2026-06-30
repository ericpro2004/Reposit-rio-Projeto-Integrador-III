import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/presenca.dart';
import '../models/presenca_model.dart';

class AttendanceRemoteDataSource {
  AttendanceRemoteDataSource(this._client);
  final SupabaseClient _client;

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  /// Roster: passageiros da conexão + presença de hoje (merge em memória).
  Future<List<RosterItem>> getRoster(String conexaoId) async {
    final passageiros = await _client
        .from('passageiros')
        .select('id, nome, usuarios(foto_url)')
        .eq('conexao_id', conexaoId)
        .order('nome');

    if (passageiros.isEmpty) return [];

    final ids = passageiros.map((p) => p['id'] as String).toList();
    final presencasRows = await _client
        .from('presencas')
        .select()
        .eq('data', _today)
        .inFilter('passageiro_id', ids);

    final presencasByPassageiro = {
      for (final row in presencasRows)
        row['passageiro_id'] as String: PresencaModel.fromMap(row),
    };

    return passageiros.map((p) {
      final id = p['id'] as String;
      final usuario = p['usuarios'];
      final fotoUrl =
          (usuario is Map) ? usuario['foto_url'] as String? : null;
      return RosterItem(
        passageiroId: id,
        nome: (p['nome'] ?? '') as String,
        fotoUrl: fotoUrl,
        presenca: presencasByPassageiro[id],
      );
    }).toList();
  }

  /// Roster em TEMPO REAL para uma DATA específica: busca os passageiros uma
  /// vez e faz stream das presenças daquele dia (Realtime), reemitindo a cada
  /// check-in (QR/manual). [data] no formato yyyy-MM-dd.
  Stream<List<RosterItem>> watchRoster(String conexaoId, String data) async* {
    final passageiros = await _client
        .from('passageiros')
        .select('id, nome, usuarios(foto_url)')
        .eq('conexao_id', conexaoId)
        .order('nome');

    final base = passageiros.map((p) {
      final usuario = p['usuarios'];
      return (
        id: p['id'] as String,
        nome: (p['nome'] ?? '') as String,
        foto: (usuario is Map) ? usuario['foto_url'] as String? : null,
      );
    }).toList();

    yield* _client
        .from('presencas')
        .stream(primaryKey: ['id'])
        .eq('data', data)
        .map((rows) {
      final byPassageiro = {
        for (final row in rows)
          row['passageiro_id'] as String: PresencaModel.fromMap(row),
      };
      return base
          .map((b) => RosterItem(
                passageiroId: b.id,
                nome: b.nome,
                fotoUrl: b.foto,
                presenca: byPassageiro[b.id],
              ))
          .toList();
    });
  }

  /// Marca presença manual (motorista). Upsert por (passageiro_id, data).
  /// [data] no formato yyyy-MM-dd (padrão: hoje).
  Future<PresencaModel> markAttendance({
    required String passageiroId,
    required PresencaStatus status,
    String? data,
  }) async {
    final row = await _client
        .from('presencas')
        .upsert(
          {
            'passageiro_id': passageiroId,
            'data': data ?? _today,
            'status': status.name,
            'origem': PresencaOrigem.manual.name,
            'horario_registro': DateTime.now().toIso8601String(),
          },
          onConflict: 'passageiro_id,data',
        )
        .select()
        .single();
    return PresencaModel.fromMap(row);
  }

  /// Registra/edita a justificativa (motorista). Marca como 'justificado'.
  /// O trigger notify_justificativa envia a justificativa ao responsável.
  Future<PresencaModel> setJustificativa({
    required String passageiroId,
    required String justificativa,
    String? data,
  }) async {
    final row = await _client
        .from('presencas')
        .upsert(
          {
            'passageiro_id': passageiroId,
            'data': data ?? _today,
            'status': PresencaStatus.justificado.name,
            'origem': PresencaOrigem.manual.name,
            'justificativa': justificativa,
            'horario_registro': DateTime.now().toIso8601String(),
          },
          onConflict: 'passageiro_id,data',
        )
        .select()
        .single();
    return PresencaModel.fromMap(row);
  }

  /// Check-in do passageiro via RPC (QR ou código).
  Future<PresencaModel> checkInByToken({
    required String token,
    required PresencaOrigem origem,
  }) async {
    final data = await _client.rpc(
      'register_presence',
      params: {'p_token': token, 'p_origem': origem.name},
    );
    final map = data is List ? data.first : data;
    return PresencaModel.fromMap(map as Map<String, dynamic>);
  }
}
