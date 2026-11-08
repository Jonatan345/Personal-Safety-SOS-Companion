# Personal Safety SOS Companion

Aplikasi Flutter untuk keselamatan pribadi: mendeteksi kemungkinan insiden
(jatuh/guncangan atau suara keras) memakai sensor bawaan HP, mengambil lokasi,
dan menyiapkan alert ke satu kontak darurat. Tidak ada perangkat keras
tambahan; semua sensor berasal dari HP.

## Masalah dan pengguna
Pengguna yang bepergian sendirian tidak punya cara cepat memberi tahu kontak
darurat saat terjatuh, mengalami kecelakaan, atau merasa tidak aman. Target
pengguna: mahasiswa dan individu yang sering bepergian atau berjalan sendirian.

## Fitur
- Deteksi jatuh/guncangan (accelerometer) dan suara keras (mikrofon)
- Hitung mundur 10 detik dengan tombol batal; tombol kembali sistem juga dicatat sebagai batal
- Lokasi GPS saat insiden; bila gagal, insiden disimpan **tanpa lokasi** dan pengguna diberi alasannya (tidak ada tautan peta palsu)
- Satu kontak darurat dengan validasi input
- Notifikasi perangkat dan SMS composer berisi tautan peta jika lokasi ada
- Riwayat insiden lokal (Hive): lihat, ubah catatan, hapus dengan konfirmasi dan urungkan
- Sinkronisasi opsional ke backend demo
- Layout adaptif (layar kecil dan besar), aman untuk keyboard, mendukung pembaca layar dan teks 200%

## Alur penggunaan
1. Beranda menampilkan kesiapan SOS dari kontak darurat yang tersimpan; atur kontak lebih dulu.
2. **Mulai Monitoring**: sensor aktif. Build debug/profile punya tombol *Simulasikan Shake/Fall* untuk uji; build rilis hanya memakai sensor.
3. Saat terdeteksi, layar insiden menghitung mundur 10 detik. Batalkan jika bukan darurat.
4. Jika tidak dibatalkan: lokasi diambil, insiden disimpan, riwayat terbuka, lalu notifikasi dan SMS composer disiapkan. Pengguna menekan kirim di aplikasi SMS.
5. Setelah kembali, monitoring tetap berjalan.

## Izin
| Izin | Kapan | Wajib |
| --- | --- | --- |
| Mikrofon | Saat Monitoring dimulai | Ya, untuk monitoring |
| Notifikasi (Android 13+) | Saat Monitoring dimulai, tanpa memblokir | Tidak; tanpa izin ini notifikasi tidak muncul tetapi SMS tetap disiapkan |
| Lokasi | Saat insiden | Tidak; tanpa lokasi insiden disimpan tanpa lokasi |

## Menjalankan
```powershell
flutter pub get
flutter run
```
Jangan menjalankan `flutter clean` setiap kali menguji: instal ulang aplikasi
menghapus data lokal.

### Backend demo (opsional)
```powershell
node backend/server.mjs
flutter run --dart-define=API_BASE_URL=http://<IP-laptop>:8080/api
```
- Port default 8080 (ubah dengan variabel `PORT`); data disimpan di `backend/data/incidents.json`.
- Endpoint: `GET/POST /api/incidents`, `PATCH/DELETE /api/incidents/:id`.
- HP dan laptop harus berada di jaringan yang sama. HTTP hanya diizinkan pada build debug; build rilis memblokir cleartext.
- Backend demo **tanpa autentikasi**: hanya untuk penggunaan lokal.
- Tanpa `API_BASE_URL`, aplikasi sepenuhnya lokal.

## Test
```powershell
flutter analyze
flutter test
node --test backend/server.test.mjs
```
Penjelasan test, kontrak perilaku, dan refactor: `docs/p9-test-refactor.md`.
Bug yang ditemukan dan test regresinya: `docs/bug-log.md`.

## Log aplikasi dan rilis
- Beranda → ikon serangga membuka **Log Aplikasi** (salin atau hapus). Log mencatat start aplikasi, sensor, insiden, sinkronisasi, dan error yang tidak tertangani, dan tetap ada setelah aplikasi ditutup.
- Cara membuat APK rilis bertanda tangan: `docs/p10-release.md`. Catatan rilis: `RELEASE_NOTES.md`.

## Dokumentasi
- `ARCHITECTURE.md`: struktur, lapisan, alur, data
- `docs/scope.md`: batas fitur
- `docs/p4-state-management.md`: state management dan enam kondisi UI
- `docs/p9-test-refactor.md`, `docs/bug-log.md`
- `docs/evidence/`: bukti per pertemuan

## Kriteria keberhasilan
- Accelerometer dan mikrofon mendeteksi pemicu dan membuka layar insiden
- GPS diambil otomatis; jika gagal, lokasi `null` dan pengguna diberi tahu
- Hitung mundur dan pembatalan berfungsi; batal tidak menyiapkan SMS
- Notifikasi dan SMS composer disiapkan; kegagalan ditampilkan dalam Bahasa Indonesia
- Riwayat tersimpan lokal dan tetap ada setelah aplikasi dibuka kembali
- Izin mikrofon, notifikasi, dan lokasi ditangani tanpa menghentikan fitur lain
- APK dapat diinstal dan dijalankan end-to-end

## Batasan
- Monitoring hanya berjalan saat aplikasi terbuka di layar
- SMS memerlukan penekanan tombol kirim oleh pengguna
- Satu kontak darurat
- Penghapusan yang gagal dikirim ke server dapat muncul kembali saat sinkronisasi
