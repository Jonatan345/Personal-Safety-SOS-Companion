/// Identitas versi yang tampil di aplikasi dan di log. Harus sama dengan
/// `version:` di pubspec.yaml (dijaga oleh test/app_info_test.dart).
abstract final class AppInfo {
  static const String name = '1.0.0';
  static const int build = 1;
  static const String label = '$name+$build';
}
