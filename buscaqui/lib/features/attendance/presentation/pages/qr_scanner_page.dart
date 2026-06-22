import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/presenca.dart';
import '../providers/attendance_providers.dart';

/// Tela 8 — Leitor de QR Code (passageiro/motorista). Abre a câmera; ao validar
/// emite feedback imediato. Inclui alternativa "Inserir código manualmente".
class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  final _controller = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    await _check(raw, PresencaOrigem.qrcode);
  }

  Future<void> _check(String token, PresencaOrigem origem) async {
    setState(() => _processing = true);
    await _controller.stop();
    final res = await ref.read(checkInControllerProvider.notifier).checkIn(
          token: token,
          origem: origem,
        );
    if (!mounted) return;
    if (res.erro == null) {
      showAppFeedback(context, 'Presença registrada com sucesso!',
          type: FeedbackType.success);
      context.go(AppRoutes.connections); // volta para a aba Início
    } else {
      showAppFeedback(context, res.erro!, type: FeedbackType.error);
      // Permite nova tentativa.
      setState(() => _processing = false);
      await _controller.start();
    }
  }

  Future<void> _manualEntry() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ManualCodeSheet(),
    );
    if (code != null && code.isNotEmpty) {
      await _check(code, PresencaOrigem.codigo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(controller: _controller, onDetect: _onDetect),
              // Moldura visual da área de leitura.
              IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Botão da lanterna sobreposto.
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Ligar/desligar lanterna',
                    color: Colors.white,
                    onPressed: () => _controller.toggleTorch(),
                    icon: const Icon(Icons.flash_on),
                  ),
                ),
              ),
              if (_processing)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  'Aponte a câmera para o QR Code da van.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Inserir código manualmente',
                icon: Icons.keyboard,
                variant: AppButtonVariant.outlined,
                onPressed: _processing ? null : _manualEntry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sheet para entrada manual do código (fallback acessível da câmera).
class _ManualCodeSheet extends StatefulWidget {
  const _ManualCodeSheet();

  @override
  State<_ManualCodeSheet> createState() => _ManualCodeSheetState();
}

class _ManualCodeSheetState extends State<_ManualCodeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_codigo.text.trim().toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text('Inserir código',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Código da van',
                  controller: _codigo,
                  hint: 'Ex.: A3F9KZ',
                  prefixIcon: Icons.tag,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => (v == null || v.trim().length < 4)
                      ? 'Código inválido. Tente novamente.'
                      : null,
                ),
                AppButton(
                  label: 'Registrar presença',
                  icon: Icons.check,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
