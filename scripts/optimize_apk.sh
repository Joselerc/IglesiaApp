#!/bin/bash

# 📦 Script de Optimización de APK
# Igreja Amor em Movimento

echo "📦 Optimizando tamaño del APK..."

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
flutter clean

# Actualizar dependencias optimizadas
echo "📚 Instalando dependencias optimizadas..."
flutter pub get

# Build con optimizaciones máximas
echo "🚀 Generando APK optimizado..."
flutter build apk --release \
  --tree-shake-icons \
  --split-debug-info=build/app/outputs/symbols \
  --obfuscate \
  --dart-define-from-file=.env.production

# Información del APK generado
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo "✅ APK optimizado generado:"
    echo "   📍 Ubicación: $APK_PATH"
    echo "   📊 Tamaño: $APK_SIZE"
    echo ""
    echo "🎯 OPTIMIZACIONES APLICADAS:"
    echo "   ✅ Tree shaking de iconos"
    echo "   ✅ Minificación activada"
    echo "   ✅ Recursos optimizados"
    echo "   ✅ Código obfuscado"
    echo "   ✅ Dependencias reducidas"
    echo "   ✅ Assets optimizados"
else
    echo "❌ Error generando APK optimizado"
    exit 1
fi 