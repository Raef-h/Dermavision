## TFLite Flutter Keep Rules
-keep class org.tensorflow.** { *; }
-keep class com.google.** { *; }
-dontwarn org.tensorflow.**
-dontwarn com.google.flatbuffers.**

## Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }

## permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

## General
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.Unsafe
