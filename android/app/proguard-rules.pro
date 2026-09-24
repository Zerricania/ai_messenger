# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Gson / JSON (если используется)
-keepattributes Signature
-keepattributes *Annotation*

# Не трогать классы с аннотациями Keep
-keep @androidx.annotation.Keep class * { *; }

# Google Play Core (требуется Flutter, отсутствует в не-Play сборках)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
