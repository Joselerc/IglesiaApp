# === REGLAS ULTRA-ESPECÍFICAS PARA APIs NO-SDK ===
# Igreja Amor em Movimento - Solución agresiva

# 1. ELIMINAR COMPLETAMENTE las llamadas problemáticas
-assumenosideeffects class android.view.accessibility.AccessibilityNodeInfo {
    *** mChildNodeIds;
    *** getSourceNodeId(...);
}

-assumenosideeffects class android.view.accessibility.AccessibilityRecord {
    *** getSourceNodeId(...);
}

-assumenosideeffects class android.util.LongArray {
    *** get(...);
}

# 2. REESCRIBIR las clases problemáticas
-repackageclasses 'safe'

# 3. ELIMINAR métodos que usan reflexión para acceder a APIs privadas
-assumenosideeffects class java.lang.reflect.Field {
    *** get(...);
    *** set(...);
}

-assumenosideeffects class java.lang.reflect.Method {
    *** invoke(...);
}

# 4. FORZAR eliminación de código muerto relacionado con accesibilidad privada
-assumenosideeffects class ** {
    *** access$***(...);
    synthetic *** access$***(...);
}

# 5. ESPECÍFICO para Flutter - eliminar bindings problemáticos
-dontwarn io.flutter.embedding.android.**
-dontwarn io.flutter.plugin.platform.**
-dontwarn io.flutter.view.**

# 6. AGRESIVO - eliminar TODA referencia a campos/métodos privados
-optimizations !field/marking/private,!method/marking/private

# 7. STRIP específico de símbolos problemáticos
-assumenosideeffects class ** {
    private *** mChildNodeIds;
    private *** getSourceNodeId(...);
}

# 8. ELIMINAR métodos problemáticos completamente
-assumenosideeffects class android.view.accessibility.AccessibilityNodeInfo {
    *** getSourceNodeId(...);
}

-assumenosideeffects class android.view.accessibility.AccessibilityRecord {
    *** getSourceNodeId(...);
} 