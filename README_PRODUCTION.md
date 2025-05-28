# 🚀 Church App BR - Guía de Producción

## 📱 Aplicativo oficial da Igreja Amor em Movimento

Esta guía contiene toda la información necesaria para preparar y publicar la aplicación en las tiendas de aplicaciones.

## 🔧 Configuración Previa a la Publicación

### 1. **Configuración de Firebase**
- [ ] Crear proyecto de Firebase para producción
- [ ] Configurar autenticación con dominio de producción
- [ ] Configurar Firestore con reglas de seguridad apropiadas
- [ ] Configurar Firebase Storage con reglas de seguridad
- [ ] **Configurar Firebase Cloud Messaging (FCM)**
- [ ] Actualizar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)

### 1.1. **Configuración Específica de FCM**
- [ ] Habilitar Firebase Cloud Messaging en la consola de Firebase
- [ ] Configurar certificados APNs para iOS (desarrollo y producción)
- [ ] Configurar Server Key para Android en Firebase Console
- [ ] Desplegar Cloud Functions para notificaciones push
- [ ] Configurar dominios autorizados para Cloud Functions
- [ ] Probar envío de notificaciones desde Firebase Console

### 2. **Configuración de Android**
- [ ] Cambiar `applicationId` en `android/app/build.gradle`
- [ ] Configurar signing key para release
- [ ] Verificar permisos en `AndroidManifest.xml`
- [ ] Configurar ProGuard rules

### 3. **Configuración de iOS**
- [ ] Configurar Bundle Identifier único
- [ ] Configurar certificados de distribución
- [ ] Verificar permisos en `Info.plist`
- [ ] Configurar App Store Connect

## 🛠️ Proceso de Build

### Usando el Script Automatizado
```bash
# Dar permisos de ejecución
chmod +x scripts/build_release.sh

# Build para Android
./scripts/build_release.sh android

# Build para iOS (solo en macOS)
./scripts/build_release.sh ios

# Build para ambas plataformas
./scripts/build_release.sh both
```

### Build Manual

#### Android
```bash
# Limpiar proyecto
flutter clean && flutter pub get

# Análisis de código
flutter analyze

# Build APK
flutter build apk --release --split-per-abi

# Build App Bundle (recomendado para Google Play)
flutter build appbundle --release
```

#### iOS
```bash
# Limpiar proyecto
flutter clean && flutter pub get

# Build iOS
flutter build ios --release

# Crear IPA
flutter build ipa --release
```

## 📋 Checklist Pre-Publicación

### ✅ **Funcionalidad**
- [ ] Login/registro funcionando correctamente
- [ ] Todas las secciones cargan sin errores
- [ ] **Notificaciones push funcionando (FCM)**
- [ ] **Notificaciones locales funcionando**
- [ ] **Navegación desde notificaciones funcionando**
- [ ] Subida de imágenes funcionando
- [ ] Reproducción de videos funcionando
- [ ] Formularios validando correctamente

### ✅ **Testing de Notificaciones Push**
- [ ] Tokens FCM se generan y guardan correctamente
- [ ] Notificaciones se reciben en primer plano
- [ ] Notificaciones se reciben en background
- [ ] Notificaciones se reciben cuando la app está cerrada
- [ ] Navegación desde notificaciones funciona correctamente
- [ ] Iconos y colores de notificaciones son correctos
- [ ] Sonidos y vibraciones funcionan
- [ ] Cloud Functions responden correctamente
- [ ] Limpieza de tokens inválidos funciona

### ✅ **Performance**
- [ ] App inicia en menos de 3 segundos
- [ ] Navegación fluida sin lag
- [ ] Imágenes se cargan correctamente
- [ ] No hay memory leaks evidentes
- [ ] Funciona bien en dispositivos de gama baja

### ✅ **Seguridad**
- [ ] Validación de entrada implementada
- [ ] Reglas de Firestore configuradas
- [ ] Permisos mínimos necesarios
- [ ] No hay logs sensibles en producción

### ✅ **UI/UX**
- [ ] Diseño responsive en diferentes tamaños
- [ ] Textos legibles y bien contrastados
- [ ] Iconos y imágenes de alta calidad
- [ ] Navegación intuitiva
- [ ] Estados de carga y error manejados

## 🏪 Publicación en Tiendas

### Google Play Store

1. **Preparación**
   - Crear cuenta de desarrollador
   - Configurar App Bundle
   - Preparar assets (iconos, screenshots, descripción)

2. **Información Requerida**
   - Título: "Amor em Movimento"
   - Descripción corta: "Aplicativo oficial da Igreja Amor em Movimento"
   - Descripción larga: Ver `pubspec.yaml`
   - Categoría: "Lifestyle" o "Social"
   - Clasificación de contenido: Para todas las edades

3. **Assets Necesarios**
   - Icono de alta resolución (512x512)
   - Screenshots (mínimo 2, máximo 8)
   - Banner de funcionalidad (1024x500)

### Apple App Store

1. **Preparación**
   - Cuenta de Apple Developer
   - Configurar App Store Connect
   - Preparar assets específicos de iOS

2. **Información Requerida**
   - Nombre: "Amor em Movimento"
   - Subtítulo: "Igreja Conectada"
   - Palabras clave: "igreja, comunidade, fé, eventos"
   - Categoría: "Lifestyle" o "Social Networking"

3. **Assets Necesarios**
   - Iconos para diferentes tamaños
   - Screenshots para diferentes dispositivos
   - Preview de video (opcional pero recomendado)

## 🔒 Configuraciones de Seguridad

### Firestore Rules (Ejemplo)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios solo pueden leer/escribir sus propios datos
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Contenido público de solo lectura
    match /announcements/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && hasRole('admin');
    }
  }
}
```

### Firebase Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user_images/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /public/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && hasRole('admin');
    }
  }
}
```

## 📊 Monitoreo Post-Lanzamiento

### Métricas Importantes
- Número de descargas
- Retención de usuarios (1 día, 7 días, 30 días)
- Crashes y errores
- Tiempo de sesión promedio
- Funcionalidades más utilizadas

### Herramientas Recomendadas
- Firebase Analytics
- Firebase Crashlytics
- Google Play Console (Android)
- App Store Connect (iOS)

## 🆘 Solución de Problemas Comunes

### Build Failures
```bash
# Limpiar completamente
flutter clean
rm -rf .dart_tool/
flutter pub get

# Verificar versión de Flutter
flutter doctor -v
```

### Problemas de Signing (Android)
- Verificar que el keystore esté configurado correctamente
- Asegurar que las credenciales sean correctas
- Verificar que el applicationId sea único

### Problemas de Certificados (iOS)
- Renovar certificados en Apple Developer
- Verificar provisioning profiles
- Limpiar derived data en Xcode

## 📞 Contacto y Soporte

Para problemas técnicos o consultas sobre la aplicación:
- Email: [tu-email@iglesia.com]
- Teléfono: [tu-teléfono]
- Documentación técnica: [enlace-a-docs]

---

**Última actualización:** Diciembre 2024
**Versión de la app:** 1.0.0
**Versión de Flutter:** 3.6.1 