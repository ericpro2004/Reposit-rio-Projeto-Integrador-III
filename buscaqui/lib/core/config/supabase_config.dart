/// Credenciais do Supabase.
///
/// NÃO commite chaves reais. Passe-as em tempo de build/execução:
///   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=ey...
///
/// No Azure DevOps Pipelines, defina-as como variáveis secretas e injete
/// via --dart-define no passo de build.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
