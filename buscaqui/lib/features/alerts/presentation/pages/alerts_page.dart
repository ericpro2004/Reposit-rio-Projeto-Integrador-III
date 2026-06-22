import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/alerta.dart';
import '../providers/alert_providers.dart';

/// Tela 10 — Alertas. Feed em tempo real de avisos enviados aos responsáveis.
class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsStreamProvider);

    return alertsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Não foi possível carregar os alertas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      data: (alertas) {
        if (alertas.isEmpty) {
          return _EmptyState();
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: alertas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (_, i) => _AlertTile(alerta: alertas[i]),
        );
      },
    );
  }
}

class _AlertTile extends ConsumerWidget {
  const _AlertTile({required this.alerta});
  final Alerta alerta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hora = DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(alerta.criadoEm);

    return Semantics(
      container: true,
      label: '${alerta.lido ? "Lido" : "Não lido"}. '
          '${alerta.mensagem}. Recebido em $hora.',
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: alerta.lido
                ? AppColors.textSecondary.withOpacity(0.15)
                : AppColors.danger.withOpacity(0.15),
            child: Icon(
              alerta.lido ? Icons.notifications_none : Icons.warning_amber,
              color: alerta.lido ? AppColors.textSecondary : AppColors.danger,
            ),
          ),
          title: Text(
            alerta.mensagem,
            style: TextStyle(
              fontWeight: alerta.lido ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(hora),
          ),
          trailing: alerta.lido
              ? null
              : Semantics(
                  button: true,
                  label: 'Marcar alerta como lido',
                  child: IconButton(
                    iconSize: 26,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.done),
                    onPressed: () => ref
                        .read(alertRepositoryProvider)
                        .markAsRead(alerta.id),
                  ),
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Nenhum alerta por aqui.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Você será avisado em tempo real sobre faltas e ocorrências.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
