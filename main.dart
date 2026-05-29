import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase (Auth + PostgREST + Realtime + Storage).
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // ProviderScope é a raiz obrigatória do Riverpod.
  runApp(const ProviderScope(child: BusCaquiApp()));
}

class BusCaquiApp extends ConsumerWidget {
  const BusCaquiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'BusCaqui',
      debugShowCheckedModeBanner: false,

      // Tema acessível (claro/escuro) — segue a preferência do sistema.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      routerConfig: router,

      // Acessibilidade: respeita o zoom de texto do sistema, mas faz "clamp"
      // entre 1.0x e 1.6x para honrar a escala dinâmica sem quebrar o layout.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final scaled = mq.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.6,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: scaled),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
