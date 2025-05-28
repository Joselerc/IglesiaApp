#!/bin/bash

# Script para build de producción de la app Church App BR
# Uso: ./scripts/build_release.sh [android|ios|both]

set -e

echo "🚀 Iniciando build de producción para Church App BR..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    log_error "Este script debe ejecutarse desde la raíz del proyecto Flutter"
    exit 1
fi

# Limpiar proyecto
log_info "Limpiando proyecto..."
flutter clean

# Obtener dependencias
log_info "Obteniendo dependencias..."
flutter pub get

# Ejecutar análisis de código
log_info "Ejecutando análisis de código..."
flutter analyze
if [ $? -ne 0 ]; then
    log_error "El análisis de código falló. Por favor, corrige los errores antes de continuar."
    exit 1
fi

# Ejecutar tests (si existen)
log_info "Ejecutando tests..."
flutter test --coverage || log_warning "Algunos tests fallaron o no hay tests configurados"

# Función para build de Android
build_android() {
    log_info "Construyendo APK de producción para Android..."
    flutter build apk --release --split-per-abi
    
    log_info "Construyendo App Bundle para Google Play Store..."
    flutter build appbundle --release
    
    log_success "Build de Android completado!"
    log_info "Archivos generados:"
    echo "  - APK: build/app/outputs/flutter-apk/"
    echo "  - App Bundle: build/app/outputs/bundle/release/"
}

# Función para build de iOS
build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "El build de iOS solo está disponible en macOS"
        return 1
    fi
    
    log_info "Construyendo IPA de producción para iOS..."
    flutter build ios --release
    
    log_success "Build de iOS completado!"
    log_info "Para crear el archivo IPA, usa Xcode o:"
    echo "  flutter build ipa --release"
}

# Determinar qué plataforma construir
PLATFORM=${1:-both}

case $PLATFORM in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    both)
        build_android
        if [[ "$OSTYPE" == "darwin"* ]]; then
            build_ios
        else
            log_warning "Saltando build de iOS (solo disponible en macOS)"
        fi
        ;;
    *)
        log_error "Plataforma no válida. Usa: android, ios, o both"
        exit 1
        ;;
esac

log_success "🎉 Build de producción completado!"

# Mostrar información adicional
echo ""
log_info "📋 Próximos pasos:"
echo "1. Testa los archivos generados en dispositivos reales"
echo "2. Verifica que todas las funcionalidades trabajen correctamente"
echo "3. Sube a las tiendas de aplicaciones correspondientes"
echo ""
log_warning "⚠️  Recuerda:"
echo "- Cambiar el applicationId en android/app/build.gradle para producción"
echo "- Configurar signing keys para release"
echo "- Actualizar los archivos de configuración de Firebase para producción" 