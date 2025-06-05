# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp - reglas completas para evitar R8 issues
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# OkHttp legacy (para grpc)
-dontwarn com.squareup.okhttp.**
-keep class com.squareup.okhttp.** { *; }
-keep interface com.squareup.okhttp.** { *; }

# gRPC OkHttp
-keep class io.grpc.okhttp.** { *; }
-dontwarn io.grpc.okhttp.**

# Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep custom model classes (adjust package name as needed)
-keep class com.amoremmovimento.church_app.models.** { *; }

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Reglas específicas para APIs No-SDK de Accesibilidad
-dontwarn android.view.accessibility.AccessibilityNodeInfo
-dontwarn android.view.accessibility.AccessibilityRecord  
-dontwarn android.util.LongArray

# Evitar reflexión en APIs No-SDK
-keepclassmembers class android.view.accessibility.** {
    public <methods>;
    public <fields>;
}

# Mantener solo APIs públicas de accesibilidad
-keep public class android.view.accessibility.AccessibilityNodeInfo {
    public <methods>;
}
-keep public class android.view.accessibility.AccessibilityRecord {
    public <methods>;
}

# Bloquear acceso a APIs privadas específicas
-assumenosideeffects class android.view.accessibility.AccessibilityNodeInfo {
    *** getSourceNodeId();
    *** mChildNodeIds;
}

-assumenosideeffects class android.view.accessibility.AccessibilityRecord {
    *** getSourceNodeId();
}

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

# === ANDROIDX.WINDOW CONSERVADOR PROTECTION ===
# Mantener androidx.window pero proteger de ProGuard agresivo
-keep class androidx.window.** { *; }
-keep class androidx.window.layout.** { *; }
-keep class androidx.window.layout.adapter.** { *; }

# Proteger específicamente los métodos que fallan
-keep class androidx.window.layout.WindowInfoTrackerImpl { *; }
-keep class androidx.window.layout.WindowInfoTrackerImpl$* { *; }

# Proteger listeners y callbacks
-keep class androidx.window.layout.a { *; }
-keep class androidx.window.layout.adapter.extensions.MulticastConsumer { *; }
-keep class androidx.window.extensions.layout.WindowLayoutComponentImpl { *; }
-keep class androidx.window.extensions.layout.WindowLayoutComponentImpl$* { *; }

# Proteger DeviceStateManager
-keep class androidx.window.common.DeviceStateManagerFoldingFeatureProducer { *; }
-keep class androidx.window.common.DeviceStateManagerFoldingFeatureProducer$* { *; }
-keep class androidx.window.common.RawFoldingFeatureProducer { *; }

# === REFUERZO ADICIONAL PARA ANDROIDX.WINDOW.SIDECAR ===
-keep class androidx.window.sidecar.** { *; } # Puede ser redundante con androidx.window.** pero asegura especificidad
-keep interface androidx.window.sidecar.** { *; }
-keep public class androidx.window.sidecar.SidecarDeviceState { *; }
-keep public class androidx.window.sidecar.SidecarDisplayFeature { *; }
-keep public interface androidx.window.sidecar.SidecarInterface { *; }
-keep public interface androidx.window.sidecar.SidecarInterface$SidecarCallback { *; }
-keep public class androidx.window.sidecar.SidecarWindowLayoutInfo { *; }
-keep class androidx.window.layout.adapter.sidecar.SidecarCompat { *; }
-keep class androidx.window.layout.adapter.sidecar.SidecarWindowBackend { *; }
-keep class androidx.window.layout.adapter.sidecar.SidecarWindowBackend$* { *; } # Para clases internas/companion
-keep class androidx.window.layout.adapter.sidecar.DistinctElementCallback { *; }

# === KOTLINX.COROUTINES PROTECTION COMPLETA ===
# Proteger TODO el sistema de corrutinas
-keep class kotlinx.coroutines.** { *; }
-keep class kotlinx.coroutines.channels.** { *; }
-keep class kotlinx.coroutines.flow.** { *; }
-keep class kotlinx.coroutines.internal.** { *; }

# Proteger específicamente BufferedChannel y sus iteradores
-keep class kotlinx.coroutines.channels.BufferedChannel { *; }
-keep class kotlinx.coroutines.channels.BufferedChannel$* { *; }
-keep class kotlinx.coroutines.channels.ChannelCoroutine { *; }

# Proteger métodos específicos que fallan
-keepclassmembers class kotlinx.coroutines.channels.BufferedChannel$BufferedChannelIterator {
    *** tryResumeHasNext(...);
}

-keepclassmembers class kotlinx.coroutines.channels.BufferedChannel {
    *** tryResumeReceiver(...);
    *** updateCellSend(...);
    *** trySend-JP2dKIU(...);
}

# === REFUERZO ADICIONAL PARA KOTLINX.COROUTINES (METADATA Y COMPONENTES INTERNOS) ===
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.android.AndroidExceptionPreHandler {}
-keepnames class kotlinx.coroutines.android.AndroidDispatcherFactory {}

-keepclassmembers class kotlin.coroutines.jvm.internal.DebugMetadata {
    <fields>;
    <methods>;
}
-keepclassmembers class kotlin.coroutines.jvm.internal.ContinuationImpl {
    <fields>;
    <methods>;
}
-keepclassmembers class kotlin.coroutines.jvm.internal.SuspendLambda {
    <fields>;
    <methods>;
}
-keepclassmembers class kotlin.coroutines.jvm.internal.RestrictedSuspendLambda {
    <fields>;
    <methods>;
}
-keepclassmembers class kotlin.coroutines.jvm.internal.YieldContinuation {
    <fields>;
    <methods>;
}
-keepclassmembers class kotlin.coroutines.jvm.internal.RunSuspend {
    <fields>;
    <methods>;
}
-keepclassmembers class kotlin.coroutines.ContinuationInterceptor {
    <fields>;
    <methods>;
}

# === REFUERZO ADICIONAL GENERAL PARA ANDROIDX.WINDOW ===
-keep public class androidx.window.** { *; }
-keepnames class androidx.window.** # Evita que los nombres de las clases cambien
-keepclassmembers public class androidx.window.** { *; } # Mantiene todos los miembros

-keep public class androidx.window.layout.** { *; }
-keepnames class androidx.window.layout.**
-keepclassmembers public class androidx.window.layout.** { *; }

-keep public class androidx.window.layout.adapter.** { *; }
-keepnames class androidx.window.layout.adapter.**
-keepclassmembers public class androidx.window.layout.adapter.** { *; }

-keep public class androidx.window.extensions.** { *; }
-keepnames class androidx.window.extensions.**
-keepclassmembers public class androidx.window.extensions.** { *; }

-keep public class androidx.window.common.** { *; }
-keepnames class androidx.window.common.**
-keepclassmembers public class androidx.window.common.** { *; } 