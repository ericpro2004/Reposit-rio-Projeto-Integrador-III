import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../constants/app_colors.dart';
import '../router/app_routes.dart';

/// Casca principal do app: barra superior (menu sanduíche + avatar do usuário),
/// Drawer com a opção Sair e a barra de navegação inferior de 5 itens.
/// O conteúdo de cada aba é fornecido pelo `StatefulShellRoute`.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  List<String> _titles(UserRole? role) => [
        'Início',
        switch (role) {
          UserRole.motorista => 'Chamada',
          UserRole.responsavel => 'Meus alunos',
          _ => 'Entrar em conexão',
        },
        switch (role) {
          UserRole.motorista => 'Gerar QR Code',
          UserRole.responsavel => 'Vincular aluno',
          _ => 'Registrar presença',
        },
        'Monitoramento',
        'Mensagens',
      ];

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Volta à raiz da aba ao tocar novamente nela.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;
    final role = ref.watch(currentAppUserProvider).valueOrNull?.role;

    return Scaffold(
      appBar: AppBar(
        // Menu sanduíche à esquerda.
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(_titles(role)[index]),
        actions: [
          // Avatar do usuário: atalho direto para Dados pessoais (configurações).
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _UserAvatarButton(
              onTap: () => context.push(AppRoutes.profile),
            ),
          ),
        ],
      ),
      drawer: const _AppDrawer(),
      body: navigationShell,
      bottomNavigationBar: _AppBottomNav(
        currentIndex: index,
        role: role,
        onTap: _goBranch,
      ),
    );
  }
}

/// Avatar circular com a inicial do nome do usuário.
class _UserAvatarButton extends ConsumerWidget {
  const _UserAvatarButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final inicial =
        (user?.nome.trim().isNotEmpty ?? false) ? user!.nome.trim()[0].toUpperCase() : '?';
    return Semantics(
      button: true,
      label: 'Conta de ${user?.nome ?? 'usuário'}. Abrir dados pessoais.',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.textPrimary,
          foregroundColor: Colors.white,
          backgroundImage:
              user?.fotoUrl != null ? NetworkImage(user!.fotoUrl!) : null,
          child: user?.fotoUrl == null
              ? Text(inicial, style: const TextStyle(fontWeight: FontWeight.bold))
              : null,
        ),
      ),
    );
  }
}

/// Drawer (menu sanduíche) com dados do usuário e a opção Sair.
class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              accountName: Text(
                user?.nome ?? 'Usuário',
                style: const TextStyle(
                    color: AppColors.onPrimary, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                '${user?.email ?? ''}${user != null ? ' · ${user.role.label}' : ''}',
                style: const TextStyle(color: AppColors.onPrimary),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.onPrimary,
                foregroundColor: AppColors.primary,
                backgroundImage:
                    user?.fotoUrl != null ? NetworkImage(user!.fotoUrl!) : null,
                child: user?.fotoUrl == null
                    ? Text(
                        (user?.nome.trim().isNotEmpty ?? false)
                            ? user!.nome.trim()[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Dados pessoais'),
              onTap: () {
                Navigator.of(context).pop(); // fecha o drawer
                context.push(AppRoutes.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Meus vínculos'),
              onTap: () {
                Navigator.of(context).pop(); // fecha o drawer
                context.push(AppRoutes.vinculos);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Sair'),
              onTap: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    // Captura o router ANTES de qualquer await/pop (o context do drawer
    // é desmontado ao fechar o menu, o que antes impedia o logout).
    final router = GoRouter.of(context);
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (sair != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
    router.go(AppRoutes.login);
  }
}

/// Barra de navegação inferior com 5 itens e botão central destacado.
class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.currentIndex,
    required this.role,
    required this.onTap,
  });

  final int currentIndex;
  final UserRole? role;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final (tab1Icon, tab1Label) = switch (role) {
      UserRole.motorista => (Icons.checklist_rounded, 'Chamada'),
      UserRole.responsavel => (Icons.family_restroom_rounded, 'Alunos'),
      _ => (Icons.link_rounded, 'Conexão'),
    };
    final (centerIcon, centerLabel) = switch (role) {
      UserRole.motorista => (Icons.qr_code_2_rounded, 'Gerar QR Code da van'),
      UserRole.responsavel =>
        (Icons.person_add_alt_1_rounded, 'Vincular-me a um aluno'),
      _ => (Icons.qr_code_scanner_rounded, 'Registrar presença, ler QR Code'),
    };

    return Material(
      color: Theme.of(context).bottomAppBarTheme.color ??
          Theme.of(context).colorScheme.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Início',
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                icon: tab1Icon,
                label: tab1Label,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _CenterNavItem(
                index: 2,
                onTap: onTap,
                selected: currentIndex == 2,
                icon: centerIcon,
                semanticLabel: centerLabel,
              ),
              _NavItem(
                index: 3,
                icon: Icons.insights_rounded,
                label: 'Monitorar',
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                index: 4,
                icon: Icons.chat_bubble_rounded,
                label: 'Mensagens',
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.currentIndex,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String label;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    final color = selected ? AppColors.primaryAccessibleText : AppColors.textSecondary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão central (amarelo) — atalho de "Registrar presença" (ler QR).
class _CenterNavItem extends StatelessWidget {
  const _CenterNavItem({
    required this.index,
    required this.onTap,
    required this.selected,
    required this.icon,
    required this.semanticLabel,
  });

  final int index;
  final ValueChanged<int> onTap;
  final bool selected;
  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          selected: selected,
          label: semanticLabel,
          child: InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                border: selected
                    ? Border.all(color: AppColors.primaryDark, width: 2.5)
                    : null,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppColors.onPrimary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
