import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Carrega variáveis de ambiente (.env declarado em assets do pubspec).
  await dotenv.load(fileName: '.env');

  // 2. Inicializa o Supabase (Auth, Realtime, Storage, Postgres).
  await SupabaseConfig.initialize();

  // 3. Orientação: mantém retrato para previsibilidade na chamada/scanner.
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  runApp(const ProviderScope(child: BusCaquiApp()));
}

class BusCaquiApp extends ConsumerWidget {
  const BusCaquiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'BusCaqui',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      // Acessibilidade: tema claro/escuro seguindo a preferência do sistema.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Localização em Português (Brasil).
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
