# Configuração nativa (Android / iOS)

As features de mapa, câmera e localização exigem permissões e chaves nativas
que **não** ficam no Dart. Faça isto antes de rodar em dispositivo.

## 1. Google Maps

Obtenha uma chave em https://console.cloud.google.com (Maps SDK for Android e
iOS habilitados) e coloque-a também no `.env` (`GOOGLE_MAPS_API_KEY`).

### Android — `android/app/src/main/AndroidManifest.xml`
Dentro de `<application>`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="SUA_GOOGLE_MAPS_KEY"/>
```

### iOS — `ios/Runner/AppDelegate.swift`
```swift
import GoogleMaps
// dentro de application(_:didFinishLaunchingWithOptions:)
GMSServices.provideAPIKey("SUA_GOOGLE_MAPS_KEY")
```

## 2. Localização (geolocator)

### Android — `AndroidManifest.xml` (acima de `<application>`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<!-- Para o motorista compartilhar com o app em segundo plano: -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

### iOS — `ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Usamos sua localização para mostrar a van em tempo real.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>O motorista compartilha a localização da van durante a rota.</string>
```

## 3. Câmera (mobile_scanner — leitura de QR)

### Android
`minSdkVersion` ≥ 21 em `android/app/build.gradle`. A permissão de câmera já é
declarada pelo plugin.

### iOS — `Info.plist`
```xml
<key>NSCameraUsageDescription</key>
<string>Usamos a câmera para ler o QR Code da van e registrar presença.</string>
```

## 4. Notificações Push (Firebase Cloud Messaging) — JÁ IMPLEMENTADO

O fluxo ponta a ponta já existe:
`presença ausente` → trigger `notify_absence` cria alerta → trigger
`after_alerta_insert_push` chama (via `pg_net`) a Edge Function
`send-alert-push` → ela busca os tokens em `fcm_tokens` e envia via FCM HTTP v1.

Falta apenas a **configuração de credenciais** (não versionada):

### App (cliente)
1. Rode `flutterfire configure` (gera `google-services.json`,
   `GoogleService-Info.plist` — ambos ignorados pelo `.gitignore`). O
   `PushService` chama `Firebase.initializeApp()` sem `firebase_options.dart`,
   então a config nativa é suficiente.
2. Android: aplicar o plugin `com.google.gms.google-services` no Gradle.
3. iOS: habilitar *Push Notifications* e *Background Modes > Remote notifications*
   no Xcode e subir a APNs key no Firebase.

O app registra o token em `fcm_tokens` automaticamente ao logar.

### Backend (Edge Function — secrets)
No Supabase → Project Settings → Edge Functions, defina:
- `FIREBASE_SERVICE_ACCOUNT` = conteúdo JSON da *service account* do Firebase
  (Project settings → Service accounts → Generate new private key).
- `EDGE_SHARED_SECRET` = um segredo forte qualquer.

E configure o mesmo segredo no banco para o trigger enviá-lo:
```sql
alter database postgres set app.edge_secret = 'MESMO_VALOR_DO_EDGE_SHARED_SECRET';
```
Sem esses segredos, o trigger ainda dispara, mas a função retorna erro/`0 enviados`.

> A função foi publicada com `verify_jwt = false` porque é um webhook do banco;
> o controle de acesso é feito pelo header `x-edge-secret`.
