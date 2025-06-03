#!/bin/bash

# Script para configurar archivos de Firebase en Codemagic
# Este script debe ejecutarse en el pipeline de Codemagic

echo "🔧 Configurando archivos de Firebase..."

# Crear google-services.json para Android desde variable de entorno
if [ -n "$GOOGLE_SERVICES_JSON" ]; then
    echo "📱 Creando google-services.json para Android..."
    echo "$GOOGLE_SERVICES_JSON" | base64 --decode > android/app/google-services.json
    echo "✅ google-services.json creado exitosamente"
else
    echo "❌ Error: Variable GOOGLE_SERVICES_JSON no encontrada"
    exit 1
fi

# Crear GoogleService-Info.plist para iOS desde variable de entorno
if [ -n "$GOOGLE_SERVICE_INFO_PLIST" ]; then
    echo "🍎 Creando GoogleService-Info.plist para iOS..."
    echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > ios/Runner/GoogleService-Info.plist
    echo "✅ GoogleService-Info.plist creado exitosamente"
else
    echo "❌ Error: Variable GOOGLE_SERVICE_INFO_PLIST no encontrada"
    exit 1
fi

# Verificar que los archivos se crearon correctamente
if [ -f "android/app/google-services.json" ] && [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "🎉 Todos los archivos de configuración de Firebase están listos!"
else
    echo "❌ Error: Faltan archivos de configuración de Firebase"
    exit 1
fi 