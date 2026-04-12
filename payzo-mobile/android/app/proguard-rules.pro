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
