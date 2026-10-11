# Flutter and its plugins rely on reflection in places R8 cannot see.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Jitsi Meet SDK: entry points are resolved by name at runtime.
-keep class org.jitsi.meet.** { *; }
-keep class org.webrtc.** { *; }

# Suppress warnings for optional dependencies these SDKs reference but do not
# ship; they are not reachable at runtime.
-dontwarn org.jitsi.**
-dontwarn org.webrtc.**

# Flutter references Play Core's deferred-component APIs, but this app does not
# use deferred components and does not ship that library. R8 fails the build
# over the dangling references unless they are explicitly ignored.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
