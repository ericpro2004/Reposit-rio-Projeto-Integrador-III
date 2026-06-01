import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Acesso centralizado e tipado às variáveis de ambiente carregadas do `.env`.
///
/// Mantém segredos fora do código-fonte versionado. Em CI/CD (Azure Pipelines)
/// estes valores são injetados como *secret variables* e o `.env` é gerado no
/// passo de build.
abstract final class Env {
  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  static String get googleMapsApiKey => _require('GOOGLE_MAPS_API_KEY');

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        'Variável de ambiente "$key" ausente. '
        'Verifique se o arquivo .env existe e está declarado em pubspec.yaml.',
      );
    }
    return value;
  }
}
