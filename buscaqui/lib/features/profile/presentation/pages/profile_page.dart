import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Tela "Dados pessoais" (menu ☰): dados do usuário + configurações do app.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentAppUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dados pessoais')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Não foi possível carregar seus dados.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        data: (user) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionTitle('Dados pessoais', Icons.person),
            if (user != null)
              _PersonalDataForm(key: ValueKey(user.id), user: user)
            else
              const Text('Faça login para ver seus dados.'),
            const SizedBox(height: 24),
            const _SectionTitle('Configurações do app', Icons.settings),
            const _SettingsSection(),
            const SizedBox(height: 24),
            const _SectionTitle('Segurança', Icons.lock),
            Card(
              child: ListTile(
                leading: const Icon(Icons.password),
                title: const Text('Trocar senha'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changePassword(context, ref),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Avançado', Icons.tune),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Recarregar meus dados'),
                    subtitle: const Text('Atualiza informações do servidor'),
                    onTap: () {
                      ref.invalidate(currentAppUserProvider);
                      showAppFeedback(context, 'Dados recarregados.',
                          type: FeedbackType.info);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: const Text('Limpar preferências do app'),
                    subtitle: const Text('Restaura tema e notificações ao padrão'),
                    onTap: () async {
                      await ref.read(settingsProvider.notifier).reset();
                      if (context.mounted) {
                        showAppFeedback(context, 'Preferências restauradas.',
                            type: FeedbackType.success);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Sobre', Icons.info_outline),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.directions_bus),
              title: Text('BusCaqui'),
              subtitle: Text('Versão 1.0.0'),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Zona de perigo', Icons.warning_amber),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: AppColors.danger),
                title: const Text('Excluir conta',
                    style: TextStyle(
                        color: AppColors.danger, fontWeight: FontWeight.bold)),
                subtitle:
                    const Text('Remove sua conta e seus dados permanentemente'),
                onTap: () => _deleteAccount(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final nova = TextEditingController();
    final confirma = TextEditingController();
    String? erro;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Trocar senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nova,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Nova senha', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirma,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Confirmar nova senha',
                    border: OutlineInputBorder()),
              ),
              if (erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(erro!,
                      style: const TextStyle(color: AppColors.danger)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nova.text.length < 8) {
                  setSt(() => erro = 'A senha deve ter ao menos 8 caracteres.');
                  return;
                }
                if (nova.text != confirma.text) {
                  setSt(() => erro = 'As senhas não coincidem.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final res = await ref.read(authRepositoryProvider).changePassword(nova.text);
    if (!context.mounted) return;
    res.match(
      (f) => showAppFeedback(context, f.message, type: FeedbackType.error),
      (_) => showAppFeedback(context, 'Senha alterada com sucesso!',
          type: FeedbackType.success),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirma = TextEditingController();
    bool habilitado = false;
    final router = GoRouter.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Excluir conta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta ação é permanente e não pode ser desfeita. Sua conta e '
                'seus dados serão removidos.\n\nDigite EXCLUIR para confirmar:',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirma,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) =>
                    setSt(() => habilitado = v.trim().toUpperCase() == 'EXCLUIR'),
                decoration: const InputDecoration(
                    hintText: 'EXCLUIR', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: habilitado ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Excluir definitivamente'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final res = await ref.read(authRepositoryProvider).deleteAccount();
    res.match(
      (f) {
        if (context.mounted) {
          showAppFeedback(context, 'Não foi possível excluir: ${f.message}',
              type: FeedbackType.error);
        }
      },
      (_) => router.go(AppRoutes.splash),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.texto, this.icon);
  final String texto;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryAccessibleText),
            const SizedBox(width: 8),
            Text(texto, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

/// Formulário de dados pessoais (nome/telefone editáveis; e-mail/tipo só leitura).
class _PersonalDataForm extends ConsumerStatefulWidget {
  const _PersonalDataForm({super.key, required this.user});
  final AppUser user;

  @override
  ConsumerState<_PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends ConsumerState<_PersonalDataForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.user.nome);
  late final _telefone = TextEditingController(text: widget.user.telefone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final res = await ref.read(authRepositoryProvider).updateProfile(
          nome: _nome.text.trim(),
          telefone: _telefone.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    res.match(
      (f) => showAppFeedback(context, f.message, type: FeedbackType.error),
      (_) {
        ref.invalidate(currentAppUserProvider);
        showAppFeedback(context, 'Dados atualizados!',
            type: FeedbackType.success);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Nome',
            controller: _nome,
            prefixIcon: Icons.badge,
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Informe seu nome.' : null,
          ),
          AppTextField(
            label: 'Telefone',
            controller: _telefone,
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          // E-mail e tipo de conta são apenas leitura.
          _ReadOnlyRow(
              icon: Icons.email, label: 'E-mail', value: widget.user.email),
          _ReadOnlyRow(
              icon: Icons.verified_user,
              label: 'Tipo de conta',
              value: widget.user.role.label),
          const SizedBox(height: 12),
          AppButton(
            label: 'Salvar alterações',
            icon: Icons.save,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Text('$label: ', style: Theme.of(context).textTheme.labelLarge),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

/// Configurações do app: tema e notificações.
class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tema', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                RadioListTile<ThemeMode>(
                  contentPadding: EdgeInsets.zero,
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (m) => controller.setThemeMode(m!),
                  title: const Text('Padrão do sistema'),
                ),
                RadioListTile<ThemeMode>(
                  contentPadding: EdgeInsets.zero,
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (m) => controller.setThemeMode(m!),
                  title: const Text('Claro'),
                ),
                RadioListTile<ThemeMode>(
                  contentPadding: EdgeInsets.zero,
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (m) => controller.setThemeMode(m!),
                  title: const Text('Escuro'),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: SwitchListTile(
            value: settings.notificationsEnabled,
            onChanged: controller.setNotifications,
            secondary: const Icon(Icons.notifications),
            title: const Text('Notificações'),
            subtitle: const Text('Receber avisos de presença e ocorrências'),
          ),
        ),
      ],
    );
  }
}
