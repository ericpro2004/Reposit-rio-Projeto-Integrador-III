import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/connection_providers.dart';

/// Tela 6 — Entrar em Conexão. O passageiro/responsável digita o código
/// alfanumérico do motorista para solicitar a entrada no grupo.
class JoinConnectionPage extends ConsumerStatefulWidget {
  const JoinConnectionPage({super.key});

  @override
  ConsumerState<JoinConnectionPage> createState() =>
      _JoinConnectionPageState();
}

class _JoinConnectionPageState extends ConsumerState<JoinConnectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final res =
        await ref.read(connectionControllerProvider.notifier).join(_codigo.text);
    if (!mounted) return;
    if (res.erro == null) {
      showAppFeedback(
        context,
        'Você entrou na conexão "${res.conexao?.nomeConexao}"!',
        type: FeedbackType.success,
      );
      context.go(AppRoutes.connections);
    } else {
      showAppFeedback(context, res.erro!, type: FeedbackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(connectionControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar em Conexão')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 8),
              Text(
                'Digite o código que o motorista compartilhou com você.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Código da conexão',
                controller: _codigo,
                hint: 'Ex.: A3F9KZ',
                prefixIcon: Icons.tag,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: (v) => (v == null || v.trim().length < 4)
                    ? 'Código inválido. Verifique e tente novamente.'
                    : null,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Solicitar entrada',
                icon: Icons.login,
                isLoading: isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Converte a entrada para maiúsculas em tempo real (códigos são uppercase).
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
