import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Tela 4 — Vínculo inicial Passageiro ↔ Responsável.
///
/// Persiste em `responsaveis` e `passageiros`. (Numa evolução, mover a
/// persistência para uma feature `passengers` com data/domain próprios.)
class PassengerInfoPage extends ConsumerStatefulWidget {
  const PassengerInfoPage({super.key});

  @override
  ConsumerState<PassengerInfoPage> createState() => _PassengerInfoPageState();
}

class _PassengerInfoPageState extends ConsumerState<PassengerInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _alunoNome = TextEditingController();
  final _alunoIdade = TextEditingController();
  final _respNome = TextEditingController();
  final _respTel = TextEditingController();
  final _respEmail = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _alunoNome,
      _alunoIdade,
      _respNome,
      _respTel,
      _respEmail,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // RPC atômica e ciente do papel: cria responsável + aluno e garante o
      // perfil, evitando falhas de FK/RLS logo após o cadastro.
      await SupabaseConfig.client.rpc('create_vinculo', params: {
        'p_aluno_nome': _alunoNome.text.trim(),
        'p_aluno_idade': int.tryParse(_alunoIdade.text.trim()),
        'p_resp_nome': _respNome.text.trim(),
        'p_resp_telefone': _respTel.text.trim(),
        'p_resp_email': _respEmail.text.trim(),
      });

      if (!mounted) return;
      showAppFeedback(context, 'Vínculo cadastrado com sucesso!',
          type: FeedbackType.success);
      context.go(AppRoutes.connections);
    } catch (_) {
      if (!mounted) return;
      showAppFeedback(
        context,
        'Não foi possível salvar os dados. Tente novamente.',
        type: FeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informações do Passageiro')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const _SectionHeader('Dados do Aluno', Icons.school),
              AppTextField(
                label: 'Nome do aluno',
                controller: _alunoNome,
                prefixIcon: Icons.badge,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Informe o nome do aluno.'
                    : null,
              ),
              AppTextField(
                label: 'Idade',
                controller: _alunoIdade,
                prefixIcon: Icons.cake,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n <= 0 || n > 120)
                      ? 'Informe uma idade válida.'
                      : null;
                },
              ),
              const SizedBox(height: 8),
              const _SectionHeader('Dados do Responsável', Icons.family_restroom),
              AppTextField(
                label: 'Nome do responsável',
                controller: _respNome,
                prefixIcon: Icons.person,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Informe o nome do responsável.'
                    : null,
              ),
              AppTextField(
                label: 'Telefone',
                controller: _respTel,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              AppTextField(
                label: 'E-mail',
                controller: _respEmail,
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Informe um e-mail válido.'
                    : null,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Salvar e continuar',
                icon: Icons.arrow_forward,
                isLoading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.icon);
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
