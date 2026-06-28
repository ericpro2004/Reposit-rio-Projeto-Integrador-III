import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/pages/alerts_page.dart';
import '../../features/attendance/presentation/pages/manual_attendance_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/passenger_info_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/connections/domain/entities/conexao.dart';
import '../../features/connections/presentation/pages/connections_page.dart';
import '../../features/connections/presentation/pages/qr_generator_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/links/presentation/pages/vinculos_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/tracking/presentation/pages/tracking_page.dart';
import '../navigation/main_shell.dart';
import '../navigation/role_tabs.dart';
import 'app_routes.dart';
import 'placeholder_page.dart';

/// Navegadores: raiz (telas full-screen) e da casca (abas).
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider do roteador. O `redirect` reage a mudanças de autenticação
/// observando [authStateChangesProvider] via [_GoRouterRefreshStream].
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _GoRouterRefreshStream(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
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
      // Telas 8-11 ainda usam PlaceholderPage até suas features serem feitas.
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
      // Abas principais (barra inferior persistente via MainShell).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.connections, // Início
              builder: (_, __) => const ConnectionsPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.joinConnection, // Conexão (aluno) / Chamada (motorista)
              builder: (_, __) => const ConnectionOrCallTab(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.qrScanner, // Centro: Ler QR (aluno) / Gerar QR (motorista)
              builder: (_, __) => const ScanOrGenerateTab(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.dashboard, // Monitorar
              builder: (_, __) => const DashboardPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.alerts, // Mensagens
              builder: (_, __) => const AlertsPage(),
            ),
          ]),
        ],
      ),
      // Telas full-screen (abertas por cima da casca).
      GoRoute(
        path: AppRoutes.tracking,
        builder: (context, state) {
          final conexao = state.extra as Conexao?;
          if (conexao == null) {
            return const PlaceholderPage(title: 'Monitoramento ao vivo');
          }
          return TrackingPage(conexao: conexao);
        },
      ),
      GoRoute(
        path: AppRoutes.qrGenerator,
        builder: (context, state) {
          final conexao = state.extra as Conexao?;
          if (conexao == null) {
            return const PlaceholderPage(title: 'Gerador de QR Code');
          }
          return QrGeneratorPage(conexao: conexao);
        },
      ),
      GoRoute(
        path: AppRoutes.manualAttendance,
        builder: (context, state) {
          final conexao = state.extra as Conexao?;
          if (conexao == null) {
            return const PlaceholderPage(title: 'Chamada Manual');
          }
          return ManualAttendancePage(
            conexaoId: conexao.id,
            nomeConexao: conexao.nomeConexao,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.vinculos,
        builder: (_, __) => const VinculosPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfilePage(),
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
