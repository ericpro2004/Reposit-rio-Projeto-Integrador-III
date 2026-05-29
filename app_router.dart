import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import 'placeholder_pages.dart';

/// Nomes/rotas centralizados para evitar strings soltas pelo app.
abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const passengerInfo = '/passenger-info';
  static const connections = '/connections';
  static const joinConnection = '/join-connection';
  static const qrGenerator = '/qr-generator';
  static const qrScanner = '/qr-scanner';
  static const manualAttendance = '/manual-attendance';
  static const alerts = '/alerts';
  static const dashboard = '/dashboard';
}

/// Expõe o cliente Supabase para a árvore de providers.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Stream do estado de autenticação — usado pelo router para redirecionar.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange,
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    // Revalida as rotas a cada mudança de sessão (login/logout).
    refreshListenable: _GoRouterRefresh(client.auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = client.auth.currentSession != null;
      final loc = state.matchedLocation;

      // A splash decide sozinha para onde ir (não interceptamos).
      if (loc == AppRoutes.splash) return null;

      const publicRoutes = {
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
      };
      final inPublic = publicRoutes.contains(loc);

      if (!loggedIn && !inPublic) return AppRoutes.welcome;
      if (loggedIn && inPublic) return AppRoutes.connections;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const PlaceholderPage(title: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const PlaceholderPage(title: 'Criar conta'),
      ),
      GoRoute(
        path: AppRoutes.passengerInfo,
        builder: (_, __) =>
            const PlaceholderPage(title: 'Informações do passageiro'),
      ),
      GoRoute(
        path: AppRoutes.connections,
        builder: (_, __) => const PlaceholderPage(title: 'Minhas conexões'),
      ),
      GoRoute(
        path: AppRoutes.joinConnection,
        builder: (_, __) => const PlaceholderPage(title: 'Entrar em conexão'),
      ),
      GoRoute(
        path: AppRoutes.qrGenerator,
        builder: (_, __) => const PlaceholderPage(title: 'Gerador de QR Code'),
      ),
      GoRoute(
        path: AppRoutes.qrScanner,
        builder: (_, __) => const PlaceholderPage(title: 'Leitor de QR Code'),
      ),
      GoRoute(
        path: AppRoutes.manualAttendance,
        builder: (_, __) => const PlaceholderPage(title: 'Chamada manual'),
      ),
      GoRoute(
        path: AppRoutes.alerts,
        builder: (_, __) => const PlaceholderPage(title: 'Alertas'),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const PlaceholderPage(title: 'Monitoramento'),
      ),
    ],
    errorBuilder: (_, state) =>
        PlaceholderPage(title: 'Rota não encontrada: ${state.uri}'),
  );
});

/// Adapta um Stream para o Listenable que o GoRouter espera no refresh.
class _GoRouterRefresh extends ChangeNotifier {
  _GoRouterRefresh(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
