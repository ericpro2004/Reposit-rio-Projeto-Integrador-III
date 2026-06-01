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

## 4. Notificações Push (Firebase Cloud Messaging)

1. Crie um projeto no Firebase e rode `flutterfire configure` (gera
   `firebase_options.dart`, `google-services.json` e `GoogleService-Info.plist`
   — todos já ignorados pelo `.gitignore`).
2. Android: aplicar o plugin `com.google.gms.google-services`.
3. O envio do push a partir do banco será feito por uma **Edge Function** do
   Supabase disparada pelo trigger de alertas (`notify_absence`) — a função lê o
   token FCM do responsável e chama a API do FCM. (A implementar.)
