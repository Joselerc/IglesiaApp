#!/bin/bash

# 🔧 Script para corregir APIs No-SDK en Flutter
# Igreja Amor em Movimento

echo "🔧 Corrección de APIs No-SDK para Play Store..."

# Crear directorio proguard si no existe
mkdir -p android/app

# Crear reglas ProGuard para resolver problemas de APIs no-SDK
cat > android/app/proguard-rules.pro << 'EOF'
# Keep androidx accessibility classes
-keep class androidx.core.view.accessibility.** { *; }
-dontwarn androidx.core.view.accessibility.**

# Keep Android accessibility classes 
-keep class android.view.accessibility.AccessibilityNodeInfo { *; }
-keep class android.view.accessibility.AccessibilityRecord { *; }
-keep class android.util.LongArray { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# General ProGuard rules for Flutter
-keep class ** {
    @io.flutter.embedding.android.ExportedAndroidApi <methods>;
}

# Keep accessibility service classes used by Flutter
-keep class android.accessibilityservice.** { *; }
-dontwarn android.accessibilityservice.**

# Prevent obfuscation of native methods
-keepclassmembers class ** {
    @io.flutter.plugin.common.MethodChannel$MethodCallHandler <methods>;
}

EOF

echo "✅ Reglas ProGuard creadas"

# Verificar que el archivo build.gradle use las reglas ProGuard
GRADLE_FILE="android/app/build.gradle"

if ! grep -q "proguardFiles" "$GRADLE_FILE"; then
    echo "📝 Agregando configuración ProGuard al build.gradle..."
    
    # Backup del archivo original
    cp "$GRADLE_FILE" "${GRADLE_FILE}.backup"
    
    # Agregar configuración ProGuard en la sección buildTypes
    sed -i '/buildTypes {/,/}/ {
        /release {/,/}/ {
            /proguardFiles/!{
                /minifyEnabled/a\
            proguardFiles getDefaultProguardFile('\''proguard-android-optimize.txt'\''), '\''proguard-rules.pro'\''
            }
        }
    }' "$GRADLE_FILE"
    
    echo "✅ Configuración ProGuard agregada a build.gradle"
else
    echo "ℹ️ Configuración ProGuard ya existe en build.gradle"
fi

# Actualizar android/app/build.gradle para target SDK más reciente
echo "📝 Actualizando target SDK..."

# Verificar targetSdkVersion
if grep -q "targetSdkVersion" "$GRADLE_FILE"; then
    sed -i 's/targetSdkVersion .*/targetSdkVersion 34/' "$GRADLE_FILE"
    echo "✅ Target SDK actualizado a 34"
fi

# Verificar compileSdkVersion
if grep -q "compileSdkVersion" "$GRADLE_FILE"; then
    sed -i 's/compileSdkVersion .*/compileSdkVersion 34/' "$GRADLE_FILE"
    echo "✅ Compile SDK actualizado a 34"
fi

echo ""
echo "🎯 CORRECCIONES APLICADAS:"
echo "  ✅ Reglas ProGuard para APIs de accesibilidad"
echo "  ✅ Configuración ProGuard en build.gradle"
echo "  ✅ Target SDK actualizado a 34"
echo ""
echo "📋 PRÓXIMOS PASOS:"
echo "  1. Ejecuta: flutter clean"
echo "  2. Ejecuta: flutter pub get"
echo "  3. Ejecuta: flutter build apk --release"
echo "  4. Prueba el APK en dispositivos reales"
echo ""
echo "🚨 IMPORTANTE:"
echo "  - Estas reglas pueden afectar la obfuscación"
echo "  - Prueba la app extensivamente después de aplicar"
echo "  - Si hay problemas, restaura desde .backup" 