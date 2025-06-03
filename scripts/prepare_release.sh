#!/bin/bash

echo "🚀 Preparando aplicación para publicación..."

# Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
flutter clean

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Generar iconos
echo "🎨 Generando iconos de la aplicación..."
dart run flutter_launcher_icons

# Ejecutar tests
echo "🧪 Ejecutando tests..."
flutter test

# Verificar que la app compile correctamente
echo "🔍 Verificando compilación Android..."
flutter build apk --debug

echo "🔍 Verificando compilación iOS..."
flutter build ios --debug --no-codesign

echo "✅ Preparación completada. Listo para crear builds de producción." 