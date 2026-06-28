import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/links_provider.dart';

/// Tela "Meus vínculos" (aberta pelo menu ☰). Mostra as relações conforme o
/// papel: motorista → passageiros por van; responsável → alunos e sua van/
/// motorista; passageiro → sua van, motorista e responsável.
class VinculosPage extends ConsumerWidget {
  const VinculosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(myLinksProvider);
    final role = linksAsync.valueOrNull?['role'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus vínculos')),
      floatingActionButton: role == 'responsavel'
          ? FloatingActionButton.extended(
              onPressed: () => _linkAluno(context, ref),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Vincular aluno'),
            )
          : null,
      body: linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar seus vínculos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        data: (data) {
          final role = data['role'] as String?;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myLinksProvider.future),
            child: switch (role) {
              'motorista' => _MotoristaView(vans: _list(data['vans'])),
              'responsavel' => _ResponsavelView(alunos: _list(data['alunos'])),
              'passageiro' => _PassageiroView(alunos: _list(data['alunos'])),
              _ => const _Empty(texto: 'Perfil sem vínculos.'),
            },
          );
        },
      ),
    );
  }

  static List<Map<String, dynamic>> _list(dynamic v) =>
      (v as List? ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();

  /// Diálogo para o responsável digitar o código do aluno e se vincular.
  Future<void> _linkAluno(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final codigo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vincular-me a um aluno'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o código de aluno que ele compartilhou com você.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Ex.: A1B2C3',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
    if (codigo == null || codigo.isEmpty || !context.mounted) return;
    try {
      final nome = await SupabaseConfig.client
          .rpc('link_responsavel_by_codigo', params: {'p_codigo': codigo});
      if (!context.mounted) return;
      ref.invalidate(myLinksProvider);
      showAppFeedback(context, 'Você agora é responsável de $nome!',
          type: FeedbackType.success);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().contains('não encontrado')
          ? 'Aluno não encontrado para este código.'
          : 'Não foi possível vincular. Verifique o código.';
      showAppFeedback(context, msg, type: FeedbackType.error);
    }
  }
}

class _MotoristaView extends StatelessWidget {
  const _MotoristaView({required this.vans});
  final List<Map<String, dynamic>> vans;

  @override
  Widget build(BuildContext context) {
    if (vans.isEmpty) {
      return const _Empty(texto: 'Você ainda não tem vans com passageiros.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Header(icon: Icons.directions_bus, texto: 'Você é o motorista de:'),
        for (final van in vans)
          _SectionCard(
            titulo: van['conexao']?.toString() ?? 'Van',
            subtitulo: 'Código: ${van['codigo'] ?? '—'}',
            filhos: [
              for (final p in VinculosPage._list(van['passageiros']))
                _PersonTile(
                  nome: p['nome']?.toString() ?? '—',
                  detalhe: p['responsavel'] != null
                      ? 'Responsável: ${p['responsavel']}'
                          '${p['responsavel_telefone'] != null ? ' · ${p['responsavel_telefone']}' : ''}'
                      : 'Sem responsável vinculado',
                  icon: Icons.person,
                ),
              if (VinculosPage._list(van['passageiros']).isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Nenhum passageiro nesta van ainda.'),
                ),
            ],
          ),
      ],
    );
  }
}

class _ResponsavelView extends StatelessWidget {
  const _ResponsavelView({required this.alunos});
  final List<Map<String, dynamic>> alunos;

  @override
  Widget build(BuildContext context) {
    if (alunos.isEmpty) {
      return const _Empty(texto: 'Você ainda não tem alunos vinculados.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Header(icon: Icons.family_restroom, texto: 'Você é responsável por:'),
        for (final a in alunos)
          _SectionCard(
            titulo: a['nome']?.toString() ?? 'Aluno',
            subtitulo: a['idade'] != null ? '${a['idade']} anos' : null,
            filhos: [
              _PersonTile(
                nome: a['van']?.toString() ?? 'Sem van',
                detalhe: 'Van',
                icon: Icons.directions_bus,
              ),
              _PersonTile(
                nome: a['motorista']?.toString() ?? 'Sem motorista',
                detalhe: 'Motorista',
                icon: Icons.badge,
              ),
            ],
          ),
      ],
    );
  }
}

class _PassageiroView extends StatelessWidget {
  const _PassageiroView({required this.alunos});
  final List<Map<String, dynamic>> alunos;

  @override
  Widget build(BuildContext context) {
    if (alunos.isEmpty) {
      return const _Empty(
          texto: 'Você ainda não está vinculado a uma van.\n'
              'Use a aba "Conexão" para entrar com o código.');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Header(icon: Icons.school, texto: 'Seus vínculos:'),
        for (final a in alunos)
          _SectionCard(
            titulo: a['nome']?.toString() ?? 'Aluno',
            subtitulo: null,
            filhos: [
              if (a['codigo'] != null)
                _CodeShare(codigo: a['codigo'].toString()),
              _PersonTile(
                nome: a['van']?.toString() ?? 'Sem van',
                detalhe: 'Van',
                icon: Icons.directions_bus,
              ),
              _PersonTile(
                nome: a['motorista']?.toString() ?? 'Sem motorista',
                detalhe: 'Motorista',
                icon: Icons.badge,
              ),
              _PersonTile(
                nome: a['responsavel']?.toString() ?? 'Sem responsável',
                detalhe: a['responsavel_telefone'] != null
                    ? 'Responsável · ${a['responsavel_telefone']}'
                    : 'Responsável',
                icon: Icons.family_restroom,
              ),
            ],
          ),
      ],
    );
  }
}

// ---- componentes visuais ----

class _Header extends StatelessWidget {
  const _Header({required this.icon, required this.texto});
  final IconData icon;
  final String texto;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAccessibleText),
          const SizedBox(width: 8),
          Text(texto, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.titulo,
    required this.subtitulo,
    required this.filhos,
  });
  final String titulo;
  final String? subtitulo;
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleLarge),
            if (subtitulo != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitulo!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            const Divider(),
            ...filhos,
          ],
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.nome,
    required this.detalhe,
    required this.icon,
  });
  final String nome;
  final String detalhe;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$detalhe: $nome',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.surface,
          child: Icon(icon, color: AppColors.primaryAccessibleText),
        ),
        title: Text(nome),
        subtitle: Text(detalhe),
      ),
    );
  }
}

/// Código de aluno (passageiro) para compartilhar com o responsável.
class _CodeShare extends StatelessWidget {
  const _CodeShare({required this.codigo});
  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code, color: AppColors.primaryAccessibleText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seu código de aluno',
                    style: Theme.of(context).textTheme.labelLarge),
                SelectableText(
                  codigo,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                ),
                const Text('Compartilhe com seu responsável.'),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Copiar código',
            child: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: codigo));
                showAppFeedback(context, 'Código copiado.',
                    type: FeedbackType.info);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.texto});
  final String texto;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off, size: 56),
            const SizedBox(height: 16),
            Text(texto,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
