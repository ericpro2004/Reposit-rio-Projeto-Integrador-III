/// Nomes e caminhos de rota centralizados (evita strings mágicas espalhadas).
abstract final class AppRoutes {
  // Fluxo público / autenticação
  static const splash = '/'; // Tela 1
  static const register = '/cadastro'; // Tela 2
  static const login = '/login'; // Tela 3
  static const passengerInfo = '/vinculo'; // Tela 4

  // Área autenticada
  static const connections = '/conexoes'; // Tela 5
  static const joinConnection = '/conexoes/entrar'; // Tela 6
  static const tracking = '/conexoes/localizacao'; // mapa em tempo real
  static const qrGenerator = '/qr/gerar'; // Tela 7 (motorista)
  static const qrScanner = '/qr/ler'; // Tela 8 (passageiro/motorista)
  static const manualAttendance = '/chamada'; // Tela 9 (motorista)
  static const alerts = '/alertas'; // Tela 10
  static const dashboard = '/monitoramento'; // Tela 11
}
