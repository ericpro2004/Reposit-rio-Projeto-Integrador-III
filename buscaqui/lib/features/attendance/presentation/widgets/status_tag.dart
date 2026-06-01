import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/presenca.dart';

/// Tag de status da presença: ícone + texto + cor (acessível — nunca só cor).
class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.status});
  final PresencaStatus? status;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      PresencaStatus.presente => (AppColors.success, Icons.check_circle, 'Presente'),
      PresencaStatus.ausente => (AppColors.danger, Icons.cancel, 'Ausente'),
      PresencaStatus.justificado =>
        (AppColors.warning, Icons.event_note, 'Justificado'),
      null => (AppColors.textSecondary, Icons.help_outline, 'Sem registro'),
    };

    return Semantics(
      label: 'Status: $label',
      child: _Pill(color: color, icon: icon, label: label),
    );
  }
}

/// Tag da origem do registro (Manual, QR Code, Código).
class OriginTag extends StatelessWidget {
  const OriginTag({super.key, required this.origem});
  final PresencaOrigem origem;

  @override
  Widget build(BuildContext context) {
    final icon = switch (origem) {
      PresencaOrigem.manual => Icons.touch_app,
      PresencaOrigem.qrcode => Icons.qr_code,
      PresencaOrigem.codigo => Icons.tag,
    };
    return Semantics(
      label: 'Origem: ${origem.label}',
      child: _Pill(color: AppColors.info, icon: icon, label: origem.label),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.icon, required this.label});
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
