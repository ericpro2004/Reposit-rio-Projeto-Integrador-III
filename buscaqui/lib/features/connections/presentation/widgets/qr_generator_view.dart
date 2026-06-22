import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/conexao.dart';
import '../providers/connection_providers.dart';

/// Conteúdo do gerador de QR de uma conexão (sem Scaffold), reutilizado pela
/// tela cheia (Tela 7) e pela aba "Gerar QR" do motorista.
class QrGeneratorView extends ConsumerStatefulWidget {
  const QrGeneratorView({super.key, required this.conexao});
  final Conexao conexao;

  @override
  ConsumerState<QrGeneratorView> createState() => _QrGeneratorViewState();
}

class _QrGeneratorViewState extends ConsumerState<QrGeneratorView> {
  late Conexao _conexao = widget.conexao;

  @override
  void didUpdateWidget(QrGeneratorView old) {
    super.didUpdateWidget(old);
    // Ao trocar a van selecionada (na aba), atualiza o QR exibido.
    if (old.conexao.id != widget.conexao.id) _conexao = widget.conexao;
  }

  Future<void> _refresh() async {
    final res = await ref
        .read(connectionControllerProvider.notifier)
        .refreshToken(_conexao.id);
    if (!mounted) return;
    if (res.conexao != null) {
      setState(() => _conexao = res.conexao!);
      showAppFeedback(context, 'Token atualizado com sucesso.',
          type: FeedbackType.success);
    } else {
      showAppFeedback(context, res.erro ?? 'Não foi possível atualizar.',
          type: FeedbackType.error);
    }
  }

  Future<void> _share() async {
    await Share.share(
      'Entre na van "${_conexao.nomeConexao}" no BusCaqui usando o código: '
      '${_conexao.codigo}',
      subject: 'Convite BusCaqui',
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _conexao.codigo));
    showAppFeedback(context, 'Código copiado.', type: FeedbackType.info);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(connectionControllerProvider).isLoading;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Mostre este QR Code aos passageiros para o check-in, ou '
          'compartilhe o código abaixo.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Center(
          child: Semantics(
            image: true,
            label: 'QR Code da conexão ${_conexao.nomeConexao}. '
                'Código em texto: ${_conexao.codigo}.',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: _conexao.qrCodeData,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.textPrimary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Semantics(
            label: 'Código da conexão: ${_conexao.codigo}',
            child: InkWell(
              onTap: _copyCode,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectableText(
                      _conexao.codigo,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(letterSpacing: 4),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        AppButton(label: 'Compartilhar', icon: Icons.share, onPressed: _share),
        const SizedBox(height: 12),
        AppButton(
          label: 'Atualizar token',
          icon: Icons.refresh,
          variant: AppButtonVariant.outlined,
          isLoading: isLoading,
          onPressed: _refresh,
          semanticLabel:
              'Atualizar token. Gera um novo código e invalida o anterior.',
        ),
      ],
    );
  }
}
