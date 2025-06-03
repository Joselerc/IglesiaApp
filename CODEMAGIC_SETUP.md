# 🚀 Configuración de Codemagic para Igreja Amor em Movimento

## 📋 Requisitos Previos

### 1. Archivos Firebase Necesarios
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)

### 2. Certificados iOS (para distribución)
- Apple Developer Account
- Certificados de distribución
- Provisioning Profiles

## 🔧 Configuración Paso a Paso

### 1. **Crear cuenta en Codemagic**
1. Ve a [codemagic.io](https://codemagic.io)
2. Regístrate con tu cuenta de GitHub
3. Autoriza el acceso a tu repositorio

### 2. **Conectar Repositorio**
1. En el dashboard de Codemagic, click "Add application"
2. Selecciona GitHub y tu repositorio `church-app`
3. Codemagic detectará automáticamente que es un proyecto Flutter

### 3. **Configurar Variables de Entorno Seguras**

#### En Codemagic Dashboard > Tu App > Environment variables:

**Variables Requeridas:**

```bash
# Firebase Configuration (Android)
GOOGLE_SERVICES_JSON
# Contenido: Base64 del archivo google-services.json
# Comando para generar: base64 -i google-services.json

# Firebase Configuration (iOS)
GOOGLE_SERVICE_INFO_PLIST
# Contenido: Base64 del archivo GoogleService-Info.plist
# Comando para generar: base64 -i GoogleService-Info.plist
```

#### Cómo generar las variables:

**Para Android:**
```bash
# En tu máquina local, donde tienes google-services.json
base64 -i android/app/google-services.json
# Copia el resultado completo
```

**Para iOS:**
```bash
# En tu máquina local, donde tienes GoogleService-Info.plist
base64 -i ios/Runner/GoogleService-Info.plist
# Copia el resultado completo
```

### 4. **Configurar Firma de iOS (Opcional)**

Si planeas distribuir en App Store:

1. **Apple Developer Account:**
   - Ve a Codemagic > Team settings > Integrations
   - Conecta tu Apple Developer account

2. **App Store Connect:**
   - Configura la integración con App Store Connect
   - Sube certificados y provisioning profiles

### 5. **Configurar Android Signing (Opcional)**

Para Google Play Store:

1. **Generar Keystore:**
```bash
keytool -genkey -v -keystore release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

2. **Subir Keystore a Codemagic:**
   - Ve a Code signing identities
   - Sube tu archivo keystore
   - Configura las variables de entorno

### 6. **Variables Adicionales (si es necesario)**

```bash
# Para Google Play (si distribuyes ahí)
GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
# Contenido: JSON credentials de Google Cloud

# Para App Store
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_PRIVATE_KEY
```

## 🏗️ Flujos de Trabajo Disponibles

### 1. **Android Workflow**
- ✅ Compilación APK
- ✅ Compilación App Bundle (AAB)
- ✅ Tests automáticos
- ✅ Análisis de código
- 📧 Notificación por email
- 🚀 Distribución opcional a Google Play

### 2. **iOS Workflow**
- ✅ Compilación IPA
- ✅ Tests automáticos
- ✅ Análisis de código
- ✅ Firma automática
- 📧 Notificación por email
- 🍎 Distribución opcional a App Store

## 🚀 Ejecutar Builds

### Triggers Automáticos:
- ✅ Push a `main` branch
- ✅ Pull Requests
- ✅ Tags de versión

### Triggers Manuales:
1. Ve a tu app en Codemagic
2. Click "Start new build"
3. Selecciona workflow (Android/iOS)
4. Click "Start build"

## 📊 Monitoreo

### Logs disponibles:
- Build logs en tiempo real
- Flutter analyze results
- Test results
- Artifact downloads

### Notificaciones:
- 📧 Email en builds exitosos
- ❌ Email en builds fallidos
- 💬 Integración con Slack (opcional)

## 🔍 Troubleshooting

### Errores Comunes:

1. **"google-services.json not found"**
   - Verifica que la variable `GOOGLE_SERVICES_JSON` esté configurada
   - Asegúrate de que el base64 sea correcto

2. **"iOS code signing failed"**
   - Verifica certificados en Apple Developer
   - Asegúrate de que el Bundle ID coincida

3. **"Build failed during tests"**
   - Los tests están configurados como `ignore_failure: true`
   - Revisa los logs para errores específicos

### Comandos de Debugging:

```yaml
# Agregar a scripts para debug
- name: Debug Firebase files
  script: |
    ls -la android/app/
    ls -la ios/Runner/
    cat android/app/google-services.json | head -5
```

## 📝 Notas Importantes

1. **Seguridad:**
   - Nunca subas archivos de configuración al repositorio
   - Usa siempre variables de entorno para datos sensibles

2. **Builds:**
   - Los builds de iOS requieren macOS (incluido en Codemagic)
   - Los builds pueden tardar 10-30 minutos

3. **Límites:**
   - Codemagic ofrece 500 minutos gratis por mes
   - Builds paralelos disponibles en planes pagos

## 🆘 Soporte

- 📖 [Documentación oficial de Codemagic](https://docs.codemagic.io)
- 💬 [Support chat de Codemagic](https://codemagic.io)
- 📧 Email: joselerc.dev@gmail.com (configurado en workflows) 