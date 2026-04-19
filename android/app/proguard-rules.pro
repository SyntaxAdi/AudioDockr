-dontwarn com.google.re2j.Matcher
-dontwarn com.google.re2j.Pattern
-dontwarn java.beans.BeanDescriptor
-dontwarn java.beans.BeanInfo
-dontwarn java.beans.IntrospectionException
-dontwarn java.beans.Introspector
-dontwarn java.beans.PropertyDescriptor
-dontwarn javax.script.ScriptEngineFactory

-keep class androidx.media3.common.** { *; }
-keep class androidx.media3.session.** { *; }
-keep class androidx.media3.exoplayer.** { *; }
-keep class org.schabi.newpipe.extractor.** { *; }

-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

-keep class io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.ajinasokan.flutterdisplaymode.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }
-keep class com.antonkarpenko.ffmpegkit.** { *; }
