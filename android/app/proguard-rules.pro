# Flutter and its plugins supply their required R8 keep rules. Add narrowly
# scoped rules here only when a release build proves a specific class needs it.

# flutter_local_notifications membaca model lewat Gson (refleksi); tanpa aturan
# ini R8 dapat merusak notifikasi pada build rilis.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
