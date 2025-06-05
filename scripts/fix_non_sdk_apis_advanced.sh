#!/bin/bash

# 🔧 Script Avanzado para Corregir APIs No-SDK
# Igreja Amor em Movimento

echo "🔧 DIAGNÓSTICO Y CORRECCIÓN AVANZADA DE APIs No-SDK..."

# Función para verificar dependencias problemáticas
check_problematic_dependencies() {
    echo "🔍 Verificando dependencias que podrían causar APIs No-SDK..."
    
    # Verificar si pubspec.lock existe
    if [ -f "pubspec.lock" ]; then
        echo "📋 Dependencias potencialmente problemáticas encontradas:"
        
        # Buscar dependencias conocidas por causar problemas
        grep -E "(flutter_accessibility|accessibility|webview|image_picker|camera)" pubspec.lock || echo "   ✅ No se encontraron dependencias problemáticas obvias"
    fi
}

# Función para agregar configuraciones específicas
add_specific_configurations() {
    echo "⚙️ Agregando configuraciones específicas..."
    
    # Crear archivo de configuración adicional para ProGuard
    cat > android/app/consumer-proguard-rules.pro << 'EOF'
# === REGLAS ESPECÍFICAS PARA APIs No-SDK ===

# Desactivar advertencias para APIs No-SDK conocidas
-dontwarn android.view.accessibility.AccessibilityNodeInfo$**
-dontwarn android.view.accessibility.AccessibilityRecord$**
-dontwarn android.util.LongArray$**

# Reemplazar llamadas problemáticas
-assumenosideeffects class * {
    *** getSourceNodeId();
    *** mChildNodeIds;
}

# Mantener solo APIs públicas estables
-keepclassmembers class android.view.accessibility.AccessibilityNodeInfo {
    public <methods>;
    !private <methods>;
    !protected <methods>;
}

-keepclassmembers class android.view.accessibility.AccessibilityRecord {
    public <methods>;
    !private <methods>;
    !protected <methods>;
}

# Evitar reflexión en clases internas
-keepclassmembers class android.util.** {
    public <methods>;
}

EOF

    echo "✅ Archivo consumer-proguard-rules.pro creado"
}

# Función para verificar la configuración actual
verify_current_config() {
    echo "🔍 Verificando configuración actual..."
    
    BUILD_GRADLE="android/app/build.gradle"
    
    if grep -q "minifyEnabled true" "$BUILD_GRADLE"; then
        echo "✅ Minificación ACTIVADA"
    else
        echo "❌ Minificación DESACTIVADA - esto es crítico para APIs No-SDK"
    fi
    
    if grep -q "shrinkResources true" "$BUILD_GRADLE"; then
        echo "✅ Shrink resources ACTIVADO"
    else
        echo "❌ Shrink resources DESACTIVADO"
    fi
    
    if grep -q "compileSdkVersion 35" "$BUILD_GRADLE"; then
        echo "✅ Compile SDK 35"
    else
        echo "⚠️ Compile SDK no es 35"
    fi
}

# Función principal de corrección
apply_fixes() {
    echo "🚀 Aplicando correcciones..."
    
    # Limpiar build anterior
    echo "🧹 Limpiando builds anteriores..."
    flutter clean
    
    # Actualizar dependencias
    echo "📚 Actualizando dependencias..."
    flutter pub get
    
    # Aplicar configuraciones específicas
    add_specific_configurations
    
    # Intentar build con configuraciones avanzadas
    echo "🔨 Construyendo APK con optimizaciones anti-APIs-No-SDK..."
    flutter build apk --release \
        --tree-shake-icons \
        --split-debug-info=build/app/outputs/symbols \
        --obfuscate \
        --dart-define="FLUTTER_WEB_USE_SKIA=true" \
        --dart-define="FLUTTER_WEB_AUTO_DETECT=false"
}

# Función para verificar el resultado
verify_result() {
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo ""
        echo "✅ APK GENERADO EXITOSAMENTE:"
        echo "   📍 Ubicación: $APK_PATH"
        echo "   📊 Tamaño: $APK_SIZE"
        echo ""
        echo "🎯 VERIFICAR MANUALMENTE:"
        echo "   1. Instalar APK en dispositivo de prueba"
        echo "   2. Subir a Google Play Console (modo interno)"
        echo "   3. Verificar que no hay alertas de APIs No-SDK"
        echo ""
        echo "🔍 Para verificar APIs No-SDK en el APK:"
        echo "   Sube el APK a Play Console y revisa la sección 'Problemas de la prueba'"
    else
        echo "❌ Error generando APK"
        echo ""
        echo "🔍 DIAGNÓSTICO DE ERRORES:"
        echo "   - Verificar errores de compilación"
        echo "   - Revisar dependencias conflictivas"
        echo "   - Verificar configuración de ProGuard"
    fi
}

# === EJECUCIÓN PRINCIPAL ===
echo "🚀 INICIANDO CORRECCIÓN AVANZADA DE APIs No-SDK..."
echo ""

# Paso 1: Diagnóstico
check_problematic_dependencies
echo ""

# Paso 2: Verificar configuración
verify_current_config
echo ""

# Paso 3: Aplicar correcciones
apply_fixes

# Paso 4: Verificar resultado
verify_result

echo ""
echo "📋 INFORMACIÓN ADICIONAL:"
echo "   🔗 Documentación: https://developer.android.com/guide/app-compatibility/restrictions-non-sdk-interfaces"
echo "   📱 Para probar: Instalar APK en dispositivo Android real"
echo "   ☁️ Para verificar: Subir a Play Console (prueba interna)" 