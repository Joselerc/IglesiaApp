# MIGRATION_WEB.md

## Contexto
Proyecto Flutter móvil con navegación actual basada en `MaterialApp` (Navigator 1.0) y rutas estáticas + `onGenerateRoute` para rutas dinámicas. La pantalla principal usa un patrón mobile-first con `BottomNavigationBar` y `IndexedStack`. Hay integración con Firebase y múltiples plugins móviles.

## Riesgos y puntos de rotura en web (alto → medio)
- **Build web falla por `record_web`**: error de compilación real en `record_web` por incompatibilidad con `record_platform_interface` (ver “Errores reales”).
- **Firebase en web no configurado**: `lib/firebase_options.dart` lanza `UnsupportedError` en `kIsWeb`; el build web fallará hasta generar opciones web con FlutterFire.
- **Notificaciones y permisos**: `FCMService` y `NotificationService` usan `flutter_local_notifications` + `permission_handler` sin aislamiento web. Esto romperá build/runtime en web.
- **Plugins sin soporte web**: hay dependencias móviles que no compilan o no funcionan en web (ver tabla). 
- **Routing web y refresh**: hoy se usa Navigator 1.0 + `onGenerateRoute`. Para deep links robustos + back/forward + refresh, se recomienda migrar a un router declarativo (Navigator 2.0) y una estrategia de URL correcta en web.
- **UI mobile-first**: `MainScreen` usa `BottomNavigationBar` y layouts centrados en móvil. En desktop esto se verá “móvil estirado” si no se introduce un shell con sidebar/topbar.
- **FCM background handler**: `FirebaseMessaging.onBackgroundMessage` no aplica en web y requiere service worker. Debe aislarse.
- **APIs de archivos**: `path_provider`, `open_file`, `flutter_image_compress` y algunas rutas de manejo de archivos no son web-friendly.

## Dependencias y compatibilidad web (auditoría inicial)
> Nota: Esta evaluación se basa en revisión de dependencias y uso en código. Algunas deben confirmarse en pub.dev cuando habilitemos red.

## Errores reales del build (FASE 0)
### 1) `record_web` falla en compilación (bloqueante)
- **Comando**: `flutter run -d chrome` / `flutter build web`
- **Error real**:
  - `record_web-1.2.2` intenta acceder a `RecordConfig.streamBufferSize` pero `record_platform_interface-1.2.0` no define ese getter.
  - Stacktrace apunta a `record_web-1.2.2/lib/recorder/delegate/mic_recorder_delegate.dart:168`.
- **Causa probable**: incompatibilidad de versiones entre `record_web` y `record_platform_interface` (override fijo a `1.2.0`).
- **Decisión concreta (FASE 0)**:
  - **Fix directo**: actualizar `record_platform_interface` a versión compatible con `record_web`, o ajustar el `dependency_overrides` para que use una versión que exponga `streamBufferSize`.
  - **Alternativa**: aislar `record` en web con imports condicionales y stubs (si el fix de versión afecta mobile).
  - **No avanzar a otras fases** hasta que este error esté resuelto.

### 2) Warnings WASM (no bloquean build JS)
- **Comando**: `flutter build web`
- **Salida real**: lint `avoid_double_and_int_checks` en `image-4.3.0` (archivos `ifd_directory.dart`).
- **Causa probable**: incompatibilidad con modo WASM (diagnóstico de dry run).
- **Decisión concreta**: **Mover a fase 2**. No bloquea `dart2js` tradicional. Si se quiere WASM en futuro, revisar actualización de `image` o flags.

### 3) L10n: mensajes sin traducir (no bloquea build)
- **Comando**: `flutter run -d chrome` / `flutter build web`
- **Salida real**: `"pt": 14 untranslated message(s).`
- **Causa probable**: strings faltantes en `pt` de `l10n`.
- **Decisión concreta**: **Mover a fase 2** (no bloqueante).

### 4) Firebase no configurado para web (bloqueante en runtime)
- **Comando**: `flutter run -d chrome`
- **Error real**:
  - `Unsupported operation: DefaultFirebaseOptions have not been configured for web`
  - Stacktrace: `lib/firebase_options.dart` al acceder a `DefaultFirebaseOptions.currentPlatform` desde `main.dart`.
- **Causa probable**: `firebase_options.dart` generado sin configuración web (lanza `UnsupportedError` en `kIsWeb`).
- **Decisión concreta (FASE 0)**:
  - **Fix directo**: generar configuración web con FlutterFire CLI y actualizar `firebase_options.dart`.
  - **Alternativa temporal**: aislar inicialización Firebase en web con guardas y un fallback controlado (si se decide no habilitar Firebase aún).
  - **No avanzar a otras fases** hasta que el arranque web no crashee.

## Estado actual del build
- `flutter build web` **pasa sin errores**.
- Persisten avisos **no bloqueantes**:
  - L10n: `pt` con 14 mensajes sin traducir.
  - WASM dry run: lints en `image-4.3.0` (no afecta `dart2js`).

## Decisiones aplicadas (FASE 0)
- **Grabación de audio en web**: deshabilitada por ahora (se removió `record` del `pubspec.yaml`).
- **Overrides**: eliminado `record_platform_interface` override para evitar incompatibilidad.

## Impacto funcional en web (FASE 0)
- **Audio recording**: no disponible en web por ahora (fase 2 si se requiere).
- **Firebase**: build web compila. En web sin configuración, la app entra en **Web Safe Mode** (no crashea).

## Web Safe Mode (implementado)
- **Qué hace**: si `Firebase.initializeApp` falla en web, la app muestra una pantalla fallback y no continúa con inicializaciones que dependen de Firebase.
- **Mensaje en consola**: “WEB SAFE MODE - Firebase Web no configurado…”
- **Cómo retirarlo**: generar configuración web con FlutterFire CLI (actualizar `firebase_options.dart`) y recompilar. Con Firebase web configurado, el modo seguro no se activa.
### Firebase
- firebase_core: **OK**
- firebase_auth: **OK**
- cloud_firestore: **OK**
- firebase_storage: **OK**
- cloud_functions: **OK**
- firebase_messaging: **Parcial** (requiere `firebase-messaging-sw.js`, configuración web, permisos web y limitaciones de background)
- firebase_performance: **Parcial** (soporte web depende de configuración y limitaciones del SDK)

### State / utilidades
- flutter_bloc: **OK**
- provider: **OK**
- rxdart: **OK**
- intl: **OK**
- timeago: **OK**
- uuid: **OK**
- crypto: **OK**
- pdf: **OK** (generación en web posible; impresión/descarga requiere manejo web)
- excel: **OK** (generación de archivos requiere descarga web)
- shared_preferences: **OK**

### UI
- cupertino_icons: **OK**
- shimmer: **OK**
- cached_network_image: **Parcial** (caché en web limitado)
- photo_view: **OK** (gestos web pueden variar)
- table_calendar: **OK**
- marquee: **OK**
- fl_chart: **OK**
- flutter_quill: **Parcial** (funcionalidad completa y atajos/clipboard a validar)
- flutter_quill_extensions: **Parcial** (upload de imágenes/archivos requiere `file_picker` web)
- intl_phone_field: **Parcial** (depende de parsing/validación; confirmar soporte web real)

### Media / archivos / dispositivos
- image_picker: **Parcial** (web usa file input; limitaciones)
- crop_your_image: **OK**
- flutter_image_compress: **NO** (no soporta web)
- file_picker: **Parcial** (web OK con limitaciones)
- path_provider: **Parcial** (rutas locales limitadas en web)
- open_file: **NO**
- permission_handler: **NO/Parcial** (web limitado; en práctica debe aislarse)
- url_launcher: **OK**
- dio: **OK** (pero descargas requieren manejo web)
- path: **OK**

### Audio / cámara / scanning
- record: **Parcial** (depende de permisos de navegador)
- just_audio: **OK/Parcial** (usa HTMLAudio; verificar features avanzadas)
- flutter_sound: **Parcial/NO** (web inestable en muchas versiones)
- mobile_scanner: **Parcial** (acceso cámara web requiere permisos y HTTPS)
- qr_flutter: **OK**
- youtube_player_flutter: **NO** (no soporta web; reemplazar por `youtube_player_iframe` o reproductor web)

### Notificaciones
- flutter_local_notifications: **NO** (no web)

## Hallazgos en código (impacto web)
- `lib/firebase_options.dart` no tiene configuración web y lanza excepción en `kIsWeb`.
- `lib/services/fcm_service.dart` y `lib/services/notification_service.dart` usan `flutter_local_notifications` y `permission_handler` sin guardas `kIsWeb`.
- `lib/main.dart` fuerza orientación vertical con `SystemChrome.setPreferredOrientations` (sin efecto en web; recomendable condicionar a `!kIsWeb`).
- Navegación actual se basa en `MaterialApp` + `routes` + `onGenerateRoute` (Navigator 1.0). Esto no garantiza URL-state completa ni un comportamiento consistente de deep links en web.
- `lib/screens/main_screen.dart` usa `BottomNavigationBar` como layout principal: para desktop se requiere `Shell` con sidebar/topbar y área de contenido.

## Decisiones propuestas (para web-first sin romper móvil)
1) **Routing web**: Migrar a router declarativo (Navigator 2.0) con rutas tipadas/claras y soporte deep links/refresh. Posibles opciones: `go_router` o router propio con `RouterConfig`.
2) **Capa de shell responsive**: Introducir un `WebShell`/`AppScaffold` con sidebar y topbar en desktop/tablet. En móvil, conservar bottom bar.
3) **Aislamiento de plugins**: Crear adaptadores/abstracciones (p. ej. `NotificationAdapter`, `FileService`, `MediaService`) con implementación web y mobile por separado.
4) **Firebase web**: Re-generar `firebase_options.dart` con FlutterFire CLI y agregar service worker para FCM si se habilitan push notifications web.
5) **Fase 2 (si aplica)**: Notificaciones web, grabación de audio avanzada, scanning continuo con cámara, youtube embed avanzado, y cualquier plugin sin soporte web estable.

## Plan por fases
### Fase 0 – Base web (bloqueante)
- Generar configuración web de Firebase (FlutterFire CLI).
- Implementar router declarativo + URL strategy web.
- Añadir `Shell` responsive (desktop/tablet/móvil) sin reescritura de pantallas.
- Aislar o desactivar plugins no web (notificaciones locales, permisos, open_file, compresión imagen).

### Fase 1 – Migración de pantallas
- Conectar pantallas existentes al nuevo router.
- Adaptar `MainScreen` a un layout web-first (sidebar + topbar + content) con breakpoints.
- Ajustar navegación desde notificaciones/deep links a rutas declarativas.

### Fase 2 – Hardening & optimización
- Performance: evitar rebuilds masivos; paginar listas grandes; `const` donde aplique.
- Accesibilidad web: navegación con teclado, focus states, tooltips, scroll correcto.
- Compatibilidad extra (notificaciones web, grabación avanzada, scanner en web).

## Checklist de validación continua
- `flutter run -d chrome`
- `flutter build web`
- Deep links + refresh + back/forward
- Resoluciones 1366x768 y 1920x1080

## Android build scripts (nota)
- **Groovy DSL activo**: el proyecto usa `android/settings.gradle` y `android/app/build.gradle`.
- **Archivos .kts archivados**: `android/settings.gradle.kts.bak`, `android/build.gradle.kts.bak`, `android/app/build.gradle.kts.bak`.
- **Motivo**: evitar ambigüedad futura con `applicationId` y plugins duplicados.

---

## Notas pendientes de confirmación
- Validar soporte web exacto de: `intl_phone_field`, `flutter_quill_extensions`, `record`, `flutter_sound`, `mobile_scanner`, `firebase_performance`.
- Revisar uso real de plugins en pantallas críticas para decidir aislamientos mínimos.
