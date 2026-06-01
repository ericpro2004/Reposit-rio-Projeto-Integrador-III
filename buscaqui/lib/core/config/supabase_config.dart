import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Inicialização e acesso ao cliente Supabase.
///
/// Deve ser chamado uma única vez em [main], após `dotenv.load` e
/// `WidgetsFlutterBinding.ensureInitialized()`.
abstract final class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  /// Atalho para o cliente já inicializado.
  static SupabaseClient get client => Supabase.instance.client;

  /// Sessão atual (ou null se não autenticado).
  static Session? get session => client.auth.currentSession;

  /// Usuário autenticado (ou null).
  static User? get currentUser => client.auth.currentUser;
}
