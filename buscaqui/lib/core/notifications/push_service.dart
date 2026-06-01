import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handler de mensagens em segundo plano (precisa ser top-level/entry-point).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Quando a mensagem traz `notification`, o sistema já exibe na bandeja.
  // Aqui poderíamos persistir/agir sobre o `data` se necessário.
}

/// Gerencia FCM: inicialização, permissões, exibição em foreground e o
/// registro do token do dispositivo na tabela `fcm_tokens`.
///
/// Toda a inicialização é resiliente: se o Firebase não estiver configurado
/// nativamente (sem `google-services.json`/plist), o app continua funcionando
/// normalmente sem push.
class PushService {
  PushService(this._client);
  final SupabaseClient _client;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'alertas',
    'Alertas',
    description: 'Avisos de presença e ocorrências do transporte.',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission();
      await _setupLocalNotifications();

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.instance.onTokenRefresh.listen(saveToken);
      _initialized = true;
    } catch (e) {
      debugPrint('Push indisponível (Firebase não configurado?): $e');
    }
  }

  /// Registra o token do dispositivo para o usuário logado.
  Future<void> registerCurrentToken() async {
    if (!_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await saveToken(token);
    } catch (e) {
      debugPrint('Falha ao obter token FCM: $e');
    }
  }

  Future<void> saveToken(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('fcm_tokens').upsert(
      {
        'usuario_id': user.id,
        'token': token,
        'plataforma': defaultTargetPlatform.name,
        'atualizado_em': DateTime.now().toIso8601String(),
      },
      onConflict: 'token',
    );
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title ?? 'BusCaqui',
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
