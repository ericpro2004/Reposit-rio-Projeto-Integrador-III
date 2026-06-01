import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/passenger_info_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'app_routes.dart';
import 'placeholder_page.dart';

/// Provider do roteador. O `redirect` reage a mudanças de autenticação
/// observando [authStateChangesProvider] via [_GoRouterRefreshStream].
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _GoRouterRefreshStream(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final isAuthed = ref.read(isAuthenticatedProvider);
      final loc = state.matchedLocation;

      const publicRoutes = {
        AppRoutes.splash,
        AppRoutes.register,
        AppRoutes.login,
        AppRoutes.passengerInfo,
      };
      final isPublic = publicRoutes.contains(loc);

      // Mantém a splash livre — ela decide para onde ir.
      if (loc == AppRoutes.splash) return null;

      if (!isAuthed && !isPublic) return AppRoutes.login;
      if (isAuthed && (loc == AppRoutes.login || loc == AppRoutes.register)) {
        return AppRoutes.connections;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashPage(),
      ),
      // As telas abaixo entram como placeholders acessíveis e serão
      // substituídas pelas implementações reais de cada feature.
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.passengerInfo,
        builder: (_, __) => const PassengerInfoPage(),
      ),
      GoRoute(
        path: AppRoutes.connections,
        builder: (_, __) => const PlaceholderPage(title: 'Minhas Conexões'),
      ),
      GoRoute(
        path: AppRoutes.joinConnection,
        builder: (_, __) => const PlaceholderPage(title: 'Entrar em Conexão'),
      ),
      GoRoute(
        path: AppRoutes.tracking,
        builder: (_, __) => const PlaceholderPage(title: 'Monitoramento ao vivo'),
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
        builder: (_, __) => const PlaceholderPage(title: 'Chamada Manual'),
      ),
      GoRoute(
        path: AppRoutes.alerts,
        builder: (_, __) => const PlaceholderPage(title: 'Alertas'),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const PlaceholderPage(title: 'Dashboard'),
      ),
    ],
    errorBuilder: (_, state) =>
        PlaceholderPage(title: 'Página não encontrada: ${state.uri}'),
  );
});

/// Ponte entre o stream do Riverpod e o `refreshListenable` do GoRouter.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref) {
    _sub = ref.listen(
      authStateChangesProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
    ref.onDispose(() => _sub.close());
  }

  late final ProviderSubscription _sub;
}
