import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Bottom sheet para o motorista nomear e criar uma nova conexão.
/// Retorna o nome digitado (ou null se cancelado).
class CreateConnectionSheet extends StatefulWidget {
  const CreateConnectionSheet({super.key});

  @override
  State<CreateConnectionSheet> createState() => _CreateConnectionSheetState();
}

class _CreateConnectionSheetState extends State<CreateConnectionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_nome.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Evita que o teclado cubra os campos.
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
                  child: Text('Nova conexão',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Nome da conexão',
                  controller: _nome,
                  hint: 'Ex.: Van Manhã — Escola Estrela',
                  prefixIcon: Icons.directions_bus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Dê um nome com ao menos 3 caracteres.'
                      : null,
                ),
                AppButton(
                  label: 'Criar conexão',
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
