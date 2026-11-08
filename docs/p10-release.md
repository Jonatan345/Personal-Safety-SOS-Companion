# P10 — Release Candidate

## 1. Keystore (sekali saja, simpan di luar repo)
```powershell
keytool -genkey -v -keystore C:\keys\sos-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Buat `android/key.properties` (sudah di-ignore Git):
```properties
storePassword=<password keystore>
keyPassword=<password key>
keyAlias=upload
storeFile=C:/keys/sos-upload.jks
```
Cadangkan file `.jks` dan password. Tanpa keduanya, pembaruan aplikasi di Play Store tidak bisa dirilis. Tanpa `key.properties`, APK ditandatangani kunci debug (hanya uji lokal).

## 2. Build dan verifikasi APK
```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
Hasil: `build\app\outputs\flutter-apk\app-release.apk`.
```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
adb shell dumpsys package com.example.sos_companion | findstr versionName
```
`versionName` harus `1.0.0`. Versi di `pubspec.yaml` dan `lib/utils/app_info.dart` harus sama (dijaga `test/app_info_test.dart`).

## 3. Uji asap di HP (instal baru)
1. Buka aplikasi; izin mikrofon dan notifikasi diminta.
2. Atur kontak darurat; beranda menampilkan namanya.
3. Mulai Monitoring; guncangkan HP; layar hitung mundur muncul.
4. Biarkan selesai: riwayat terbuka, SMS composer terbuka.
5. Beranda → ikon serangga: log berisi `Aplikasi dimulai`, `Sensor aktif`, `Pemicu terdeteksi`, `Insiden terkirim`.
6. Tutup dan buka lagi: kontak, riwayat, dan log masih ada.

## 4. Tag rilis
```powershell
git tag v1.0.0-rc.1
git push origin v1.0.0-rc.1
```
Lampirkan `app-release.apk` dan `RELEASE_NOTES.md` pada GitHub Release.

## 5. Mengambil log dari HP pengguna
Beranda → ikon serangga → **Salin log** → tempel ke pesan. Log juga muncul di
`flutter logs` / `adb logcat` saat HP tersambung.

## 6. Google Play (opsional, lebih baik)
```powershell
flutter build appbundle --release
```
Yang harus dipenuhi dulu:
- Ganti `applicationId` dan `namespace` di `android/app/build.gradle.kts` (Play menolak `com.example.*`) dan pindahkan folder paket `MainActivity` sesuai nama baru.
- Akun Play Console, ikon dan screenshot toko, deskripsi.
- Kebijakan privasi yang menyebut penggunaan lokasi, mikrofon, dan notifikasi, serta formulir Data Safety.
- Unggah ke jalur Internal testing lebih dulu.
