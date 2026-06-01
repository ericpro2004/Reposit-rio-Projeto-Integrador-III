import 'package:flutter/material.dart';

/// Página temporária acessível usada enquanto cada feature (Telas 2–11)
/// não tem sua implementação final. Mantém o app navegável e testável.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            header: true,
            child: Text(
              'Tela "$title" em construção',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ),
    );
  }
}
