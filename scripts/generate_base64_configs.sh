#!/bin/bash

# Script para generar las variables base64 necesarias para Codemagic
# Ejecutar desde la raíz del proyecto

echo "🔧 Generando variables base64 para Codemagic..."
echo ""

# Verificar si existen los archivos necesarios
GOOGLE_SERVICES_FILE="android/app/google-services.json"
GOOGLE_SERVICE_INFO_FILE="ios/Runner/GoogleService-Info.plist"

echo "📋 Verificando archivos..."

if [ -f "$GOOGLE_SERVICES_FILE" ]; then
    echo "✅ Encontrado: $GOOGLE_SERVICES_FILE"
    echo ""
    echo "📱 GOOGLE_SERVICES_JSON (para Codemagic):"
    echo "----------------------------------------"
    base64 -i "$GOOGLE_SERVICES_FILE"
    echo ""
    echo "👆 Copia este valor completo y agrégalo como variable GOOGLE_SERVICES_JSON en Codemagic"
    echo ""
else
    echo "❌ No encontrado: $GOOGLE_SERVICES_FILE"
    echo "💡 Descarga este archivo desde Firebase Console > Project Settings > General > Your apps > Android app"
    echo ""
fi

if [ -f "$GOOGLE_SERVICE_INFO_FILE" ]; then
    echo "✅ Encontrado: $GOOGLE_SERVICE_INFO_FILE"
    echo ""
    echo "🍎 GOOGLE_SERVICE_INFO_PLIST (para Codemagic):"
    echo "-----------------------------------------------"
    base64 -i "$GOOGLE_SERVICE_INFO_FILE"
    echo ""
    echo "👆 Copia este valor completo y agrégalo como variable GOOGLE_SERVICE_INFO_PLIST en Codemagic"
    echo ""
else
    echo "❌ No encontrado: $GOOGLE_SERVICE_INFO_FILE"
    echo "💡 Descarga este archivo desde Firebase Console > Project Settings > General > Your apps > iOS app"
    echo ""
fi

echo "🔗 Links útiles:"
echo "• Firebase Console: https://console.firebase.google.com"
echo "• Codemagic Dashboard: https://codemagic.io/apps"
echo ""
echo "📝 Próximos pasos:"
echo "1. Copia las variables base64 generadas arriba"
echo "2. Ve a tu app en Codemagic > Environment variables"
echo "3. Agrega las variables como 'Secure'"
echo "4. Ejecuta un build!" 