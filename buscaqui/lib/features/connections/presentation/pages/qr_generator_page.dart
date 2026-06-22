import 'package:flutter/material.dart';

import '../../domain/entities/conexao.dart';
import '../widgets/qr_generator_view.dart';

/// Tela 7 — Gerador de QR Code (versão tela cheia, aberta pelo card da van).
class QrGeneratorPage extends StatelessWidget {
  const QrGeneratorPage({super.key, required this.conexao});

  final Conexao conexao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(conexao.nomeConexao)),
      body: SafeArea(child: QrGeneratorView(conexao: conexao)),
    );
  }
}
