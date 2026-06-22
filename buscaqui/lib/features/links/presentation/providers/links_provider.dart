import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Vínculos do usuário logado (motorista/responsável/passageiro), via RPC
/// `my_links` (SECURITY DEFINER). Recarrega ao mudar a autenticação.
final myLinksProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  ref.watch(authStateChangesProvider);
  final data = await SupabaseConfig.client.rpc('my_links');
  return (data as Map).cast<String, dynamic>();
});
