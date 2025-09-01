# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Firebase classes (since you're using FlutterFire)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Google Play Core classes for SplitCompat
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-dontwarn com.google.android.play.core.**

# General rules for Android and Kotlin
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class kotlin.** { *; }
-dontwarn kotlin.**