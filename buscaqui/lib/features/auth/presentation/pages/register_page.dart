import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/sign_up.dart';
import '../providers/auth_controller.dart';
import '../providers/auth_provider.dart';

/// Tela 2 — Cadastro. Formulário com validação descritiva, seleção de perfil
/// acessível e botões de OAuth (Google/Apple).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _celular = TextEditingController();
  final _senha = TextEditingController();
  final _confirmar = TextEditingController();
  UserRole _role = UserRole.responsavel;

  @override
  void dispose() {
    for (final c in [_nome, _email, _celular, _senha, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).signUp(
          SignUpParams(
            nome: _nome.text,
            email: _email.text,
            telefone: _celular.text,
            senha: _senha.text,
            confirmarSenha: _confirmar.text,
            role: _role,
          ),
        );
    if (!mounted) return;
    if (ok) {
      showAppFeedback(context, 'Conta criada com sucesso!',
          type: FeedbackType.success);
      context.go(AppRoutes.passengerInfo);
    } else {
      final err = ref.read(authControllerProvider).error;
      showAppFeedback(
        context,
        err is Failure ? err.message : 'Não foi possível concluir o cadastro.',
        type: FeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar minha conta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AppTextField(
                label: 'Nome completo',
                controller: _nome,
                prefixIcon: Icons.person,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Informe seu nome.' : null,
              ),
              AppTextField(
                label: 'E-mail',
                controller: _email,
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Informe um e-mail válido.'
                    : null,
              ),
              AppTextField(
                label: 'Celular',
                controller: _celular,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              AppTextField(
                label: 'Senha',
                controller: _senha,
                prefixIcon: Icons.lock,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.length < 8)
                    ? 'A senha deve ter pelo menos 8 caracteres.'
                    : null,
              ),
              AppTextField(
                label: 'Confirmar senha',
                controller: _confirmar,
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    v != _senha.text ? 'As senhas não coincidem.' : null,
              ),
              const SizedBox(height: 8),
              _RoleSelector(
                value: _role,
                onChanged: (r) => setState(() => _role = r),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Cadastrar',
                icon: Icons.check,
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              const _OrDivider(),
              const SizedBox(height: 16),
              AppButton(
                label: 'Continuar com Google',
                icon: Icons.g_mobiledata,
                variant: AppButtonVariant.outlined,
                onPressed: () =>
                    ref.read(authRepositoryProvider).signInWithGoogle(),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Continuar com Apple',
                icon: Icons.apple,
                variant: AppButtonVariant.outlined,
                onPressed: () =>
                    ref.read(authRepositoryProvider).signInWithApple(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seleção de perfil com `RadioListTile` (acessível e com label, não só cor).
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});
  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Eu sou:', style: Theme.of(context).textTheme.labelLarge),
        for (final role in UserRole.values)
          RadioListTile<UserRole>(
            value: role,
            groupValue: value,
            onChanged: (r) => onChanged(r!),
            title: Text(role.label),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou', style: Theme.of(context).textTheme.labelLarge),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
