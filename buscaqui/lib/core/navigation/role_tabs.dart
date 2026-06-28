import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/attendance/presentation/pages/chamada_tab.dart';
import '../../features/attendance/presentation/pages/qr_scanner_page.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/connections/presentation/pages/join_connection_page.dart';
import '../../features/connections/presentation/pages/qr_generator_tab.dart';
import '../../features/links/presentation/pages/alunos_tab.dart';
import '../../features/links/presentation/pages/vincular_aluno_tab.dart';

/// Aba 1 (rodapé) por papel: motorista → Chamada; responsável → Alunos;
/// passageiro → Entrar em conexão.
class ConnectionOrCallTab extends ConsumerWidget {
  const ConnectionOrCallTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentAppUserProvider).valueOrNull?.role;
    if (role == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return switch (role) {
      UserRole.motorista => const ChamadaTab(),
      UserRole.responsavel => const AlunosTab(),
      UserRole.passageiro => const JoinConnectionPage(),
    };
  }
}

/// Aba central (rodapé) por papel: motorista → Gerar QR; responsável →
/// Vincular aluno; passageiro → Ler QR.
class ScanOrGenerateTab extends ConsumerWidget {
  const ScanOrGenerateTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentAppUserProvider).valueOrNull?.role;
    if (role == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return switch (role) {
      UserRole.motorista => const QrGeneratorTab(),
      UserRole.responsavel => const VincularAlunoTab(),
      UserRole.passageiro => const QrScannerPage(),
    };
  }
}
