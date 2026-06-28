import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/links_provider.dart';

/// Aba central do responsável: vincular-se a um aluno pelo código de aluno.
class VincularAlunoTab extends ConsumerStatefulWidget {
  const VincularAlunoTab({super.key});

  @override
  ConsumerState<VincularAlunoTab> createState() => _VincularAlunoTabState();
}

class _VincularAlunoTabState extends ConsumerState<VincularAlunoTab> {
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final nome = await SupabaseConfig.client.rpc(
        'link_responsavel_by_codigo',
        params: {'p_codigo': _codigo.text.trim()},
      );
      if (!mounted) return;
      ref.invalidate(myLinksProvider);
      ref.invalidate(attendanceOverviewProvider);
      _codigo.clear();
      showAppFeedback(context, 'Você agora é responsável de $nome!',
          type: FeedbackType.success);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('não encontrado')
          ? 'Aluno não encontrado para este código.'
          : 'Não foi possível vincular. Verifique o código.';
      showAppFeedback(context, msg, type: FeedbackType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.person_add_alt_1, size: 56),
            const SizedBox(height: 12),
            Text(
              'Vincular-me a um aluno',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Peça ao aluno o "código de aluno" (em Meus vínculos) e digite-o '
              'abaixo para se tornar responsável por ele.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Código do aluno',
              controller: _codigo,
              hint: 'Ex.: A1B2C3',
              prefixIcon: Icons.tag,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                _UpperCaseFormatter(),
                LengthLimitingTextInputFormatter(8),
              ],
              onFieldSubmitted: (_) => _submit(),
              validator: (v) => (v == null || v.trim().length < 4)
                  ? 'Código inválido. Verifique e tente novamente.'
                  : null,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Vincular',
              icon: Icons.link,
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}
