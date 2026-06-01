import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_controller.dart';

/// Tela 3 — Login. E-mail/senha, "Entrar", "Esqueci minha senha" e atalho
/// para cadastro.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text, senha: _senha.text);
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.connections);
    } else {
      final err = ref.read(authControllerProvider).error;
      showAppFeedback(
        context,
        err is Failure ? err.message : 'Não foi possível entrar.',
        type: FeedbackType.error,
      );
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      showAppFeedback(context, 'Digite seu e-mail para recuperar a senha.',
          type: FeedbackType.info);
      return;
    }
    final error =
        await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    showAppFeedback(
      context,
      error ?? 'Enviamos um link de recuperação para o seu e-mail.',
      type: error == null ? FeedbackType.success : FeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 8),
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
                label: 'Senha',
                controller: _senha,
                prefixIcon: Icons.lock,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe sua senha.' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'Esqueci minha senha',
                  variant: AppButtonVariant.text,
                  expand: false,
                  onPressed: _forgotPassword,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Entrar',
                icon: Icons.login,
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ainda não tem conta?',
                      style: Theme.of(context).textTheme.bodyMedium),
                  AppButton(
                    label: 'Cadastre-se',
                    variant: AppButtonVariant.text,
                    expand: false,
                    onPressed: () => context.push(AppRoutes.register),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
