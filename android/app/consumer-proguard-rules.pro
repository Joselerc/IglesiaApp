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

# Reglas específicas para Flutter y accesibilidad
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-dontwarn io.flutter.embedding.android.**

# Evitar uso de APIs No-SDK en dependencias
-keepclassmembers class ** {
    !private <methods>;
    !synthetic <methods>;
}

# === CORRECCIONES ADICIONALES PARA R8 ===

# Firebase y gRPC dependencies
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**

# Evitar eliminación excesiva en R8
-dontwarn com.squareup.**
-keep class com.squareup.** { *; }

# Mantener clases de conectividad
-keep class javax.net.ssl.** { *; }
-keep class javax.security.** { *; } 