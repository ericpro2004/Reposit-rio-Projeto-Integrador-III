import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/notifications/push_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Carrega variáveis de ambiente (.env declarado em assets do pubspec).
  await dotenv.load(fileName: '.env');

  // Formatação de datas em pt-BR (usada em alertas, dashboard, etc.).
  await initializeDateFormatting('pt_BR', null);

  // 2. Inicializa o Supabase (Auth, Realtime, Storage, Postgres).
  await SupabaseConfig.initialize();

  // 3. Orientação: mantém retrato para previsibilidade na chamada/scanner.
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  runApp(const ProviderScope(child: BusCaquiApp()));
}

class BusCaquiApp extends ConsumerStatefulWidget {
  const BusCaquiApp({super.key});

  @override
  ConsumerState<BusCaquiApp> createState() => _BusCaquiAppState();
}

class _BusCaquiAppState extends ConsumerState<BusCaquiApp> {
  @override
  void initState() {
    super.initState();
    // Inicializa o push de forma resiliente e registra o token se já logado.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final push = ref.read(pushServiceProvider);
      await push.initialize();
      await push.registerCurrentToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Ao entrar (login/cadastro), registra o token FCM do dispositivo.
    ref.listen(authStateChangesProvider, (_, next) {
      if (next.valueOrNull?.event == AuthChangeEvent.signedIn) {
        ref.read(pushServiceProvider).registerCurrentToken();
      }
    });

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
