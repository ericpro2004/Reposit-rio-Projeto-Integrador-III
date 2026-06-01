import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../constants/app_colors.dart';

/// Feedback acessível: além do SnackBar visual, envia um anúncio ao leitor de
/// tela (live region) para que o resultado seja percebido sem depender da cor.
enum FeedbackType { success, error, info }

void showAppFeedback(
  BuildContext context,
  String message, {
  FeedbackType type = FeedbackType.info,
}) {
  // Anúncio para TalkBack/VoiceOver.
  SemanticsService.announce(message, TextDirection.ltr);

  final (color, icon) = switch (type) {
    FeedbackType.success => (AppColors.success, Icons.check_circle),
    FeedbackType.error => (AppColors.danger, Icons.error),
    FeedbackType.info => (AppColors.info, Icons.info),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
}
