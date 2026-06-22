import 'package:flutter/material.dart';

import '../widgets/roster_view.dart';

/// Tela 9 — Chamada (versão tela cheia, aberta a partir do card da van).
/// Mostra a lista de presença em tempo real de uma conexão.
class ManualAttendancePage extends StatelessWidget {
  const ManualAttendancePage({
    super.key,
    required this.conexaoId,
    required this.nomeConexao,
  });

  final String conexaoId;
  final String nomeConexao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chamada — $nomeConexao')),
      body: RosterView(conexaoId: conexaoId),
    );
  }
}
