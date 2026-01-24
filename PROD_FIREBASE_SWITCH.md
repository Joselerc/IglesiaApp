# Firebase Production Switch (igreja-amor-em-movimento)

## Diagnóstico (estado actual en este repo)
- Android
  - `android/app/google-services.json` usa `project_id = "igreja-amor-em-movimento"` (producción).
  - Ese archivo solo incluye `package_name`:
    - `com.iglesia.iglesia_app`
    - `com.igrejamoremovimento.app`
  - `android/app/build.gradle` define `applicationId "com.igrejamoremovimento.igreja"`.
  - Conclusión: el `google-services.json` actual **no** tiene un `client` que coincida con el `applicationId` real de producción.
- iOS
  - `ios/Runner/GoogleService-Info.plist` apunta a `PROJECT_ID = "iglesiaapp-2dc33"` (sandbox) y `BUNDLE_ID = "com.masiglesia.demo"`.
  - `ios/Runner.xcodeproj/project.pbxproj` usa `PRODUCT_BUNDLE_IDENTIFIER = "com.igrejamoremovimento.igreja"`.
  - Conclusión: el plist de iOS está apuntando a sandbox y con bundleId distinto al real de producción.
- Flutter
  - `lib/firebase_options.dart` apunta a `projectId = "igreja-amor-em-movimento"` para Android/iOS/Web.
  - `lib/main.dart` inicializa con `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
  - Conclusión: el runtime Flutter usa opciones de producción, pero los archivos nativos están inconsistentes.
- Archivos auxiliares
  - `firebase_options.json` apunta a `projectId = "churchappbr"` (parece legacy; solo usado por FlutterFire CLI).
  - `google-services.json` en la raíz apunta a `iglesiaapp-2dc33` (sandbox). Android usa el de `android/app/` por defecto.

## Cambios mínimos requeridos
### Android (producción)
1. En Firebase Console del proyecto **igreja-amor-em-movimento**, crear/validar un Android app con package **com.igrejamoremovimento.igreja**.
2. Descargar el `google-services.json` de ese app.
3. Reemplazar **exactamente** `android/app/google-services.json` con el nuevo archivo.
   - Debe contener un `client` cuyo `package_name` sea `com.igrejamoremovimento.igreja`.

### iOS (producción)
1. En Firebase Console del proyecto **igreja-amor-em-movimento**, crear/validar un iOS app con bundleId **com.igrejamoremovimento.igreja**.
2. Descargar el `GoogleService-Info.plist`.
3. Reemplazar **exactamente** `ios/Runner/GoogleService-Info.plist` con el nuevo archivo.

### Flutter Web (si aplica)
- `lib/firebase_options.dart` ya apunta a **igreja-amor-em-movimento**.
- Si quieres regenerar para asegurar consistencia:
  - `flutterfire configure --project=igreja-amor-em-movimento`

## Checklist de verificación (antes de subir)
### 1) Validar archivos correctos
- Android (`android/app/google-services.json`)
  - `project_info.project_id = "igreja-amor-em-movimento"`
  - Existe `client[].client_info.android_client_info.package_name = "com.igrejamoremovimento.igreja"`
- iOS (`ios/Runner/GoogleService-Info.plist`)
  - `PROJECT_ID = "igreja-amor-em-movimento"`
  - `BUNDLE_ID = "com.igrejamoremovimento.igreja"`

### 2) Comandos recomendados
- `flutter clean`
- `flutter pub get`
- (opcional) `flutterfire configure --project=igreja-amor-em-movimento`
- Android: `flutter build appbundle --release`
- iOS: `flutter build ipa --release` (o build Release en Xcode)

### 3) Confirmar project_id en runtime
Agregar temporalmente (solo debug) un log:
```dart
final options = Firebase.app().options;
debugPrint('Firebase projectId: ${options.projectId}');
debugPrint('Firebase appId: ${options.appId}');
```
- Android: revisar `adb logcat` o `flutter run --debug`.
- iOS: revisar Xcode console o `flutter run --debug`.
Debe mostrar `igreja-amor-em-movimento`.

### 4) Validar Auth/Firestore
- Auth: iniciar sesión con un usuario conocido de producción.
- Firestore: leer un documento conocido que solo exista en producción.
- (Opcional) crear un documento de prueba y verificar que aparece en Firebase Console prod.

## Plan de rollout seguro
1. Preparar un nuevo build con la configuración correcta.
2. QA interno con build de distribución (TestFlight / Internal testing):
   - projectId correcto en runtime
   - Auth y Firestore apuntan a prod
3. Publicar una nueva versión en App Store y Play Store.
   - Nota: **no es posible cambiar la app ya publicada sin subir un update**.
4. Monitorear métricas/errores (Crashlytics, Analytics, logs) post‑release.
5. Riesgos de datos/usuarios y mitigaciones:
   - Si hay usuarios/datos en ambos proyectos, los usuarios del sandbox no verán sus datos en prod.
   - Mitigaciones posibles:
     - Migrar usuarios Auth (export/import) y datos Firestore (export/import o script).
     - En el repo existe `migrate_firestore.js`; revisarlo antes de usar.
     - Comunicación a usuarios y/o re-login si cambian credenciales.
