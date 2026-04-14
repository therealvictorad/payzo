# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dio / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class com.squareup.okhttp3.** { *; }

# WebView
-keep class android.webkit.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keepclassmembers class **$WhenMappings { *; }

# Google Play Core (referenced by Flutter deferred components — suppress R8 warnings)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
