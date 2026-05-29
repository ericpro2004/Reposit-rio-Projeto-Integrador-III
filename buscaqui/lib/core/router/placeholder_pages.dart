import 'package:flutter/material.dart';

/// Placeholder acessível para telas em construção (Telas 2 a 11).
/// Substitua cada uma pela implementação real dentro de sua feature.
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
            label: 'Tela $title em construção',
            child: Text(
              'Tela "$title"\nem construção.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
