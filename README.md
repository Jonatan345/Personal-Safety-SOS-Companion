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
- Tombol SOS manual (panic button) di Beranda dengan tekan-tahan 2 detik (aksesibel pembaca layar)
- Monitoring tetap berjalan di latar belakang / saat layar mati lewat Foreground Service Android dengan notifikasi permanen dan tombol Hentikan
- Hitung mundur dengan tombol batal; tombol kembali sistem juga dicatat sebagai batal
- Lokasi GPS saat insiden; bila gagal, insiden disimpan **tanpa lokasi** dan pengguna diberi alasannya (tidak ada tautan peta palsu)
- Satu kontak darurat dengan validasi input
- Notifikasi perangkat dan SMS composer berisi tautan peta jika lokasi ada (tanpa tanda "+" pada spasi pesan)
- Riwayat insiden lokal (Hive): lihat, ubah catatan, hapus dengan konfirmasi dan urungkan, menampilkan sumber pemicu (Manual, Guncangan, Suara keras)
- Sinkronisasi opsional ke backend demo
- Layout adaptif (layar kecil dan besar), aman untuk keyboard, mendukung pembaca layar dan teks 200%

## Alur penggunaan
1. Beranda menampilkan kesiapan SOS dari kontak darurat yang tersimpan; atur kontak lebih dulu.
2. Pengguna dapat memicu SOS manual langsung dari Beranda dengan menekan dan menahan tombol **SOS MANUAL** selama 2 detik.
3. **Mulai Monitoring**: sensor aktif dan foreground service dimulai dengan notifikasi permanen "Monitoring SOS aktif" yang dilengkapi tombol **Hentikan**. Build debug/profile punya tombol *Simulasikan Shake/Fall* untuk uji; build rilis hanya memakai sensor.
4. Deteksi sensor tetap berjalan di latar belakang bahkan saat layar HP dikunci atau HP diletakkan di saku. Saat pemicu terdeteksi, aplikasi membangunkan layar dan membuka layar hitung mundur.
5. Saat terdeteksi, layar insiden menghitung mundur (10 detik untuk sensor otomatis, 3 detik untuk pemicu manual). Batalkan jika bukan darurat.
6. Jika tidak dibatalkan: waktu dicatat, lokasi diambil, insiden disimpan bersama sumber pemicunya, riwayat terbuka, lalu notifikasi dan SMS composer disiapkan. Pengguna menekan kirim di aplikasi SMS.
7. Setelah kembali, monitoring tetap berjalan.

## Izin
| Izin | Kapan | Wajib |
| --- | --- | --- |
| Mikrofon (`RECORD_AUDIO`) | Saat Monitoring dimulai | Ya, untuk deteksi suara keras |
| Foreground Service (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`, `FOREGROUND_SERVICE_HEALTH`) | Saat Monitoring aktif di latar belakang / layar mati | Ya di Android 14+, agar OS tidak menghentikan sensor saat HP di saku/layar terkunci |
| Full Screen Intent (`USE_FULL_SCREEN_INTENT`) & Wake Lock (`WAKE_LOCK`) | Saat pemicu darurat terdeteksi di latar belakang | Ya, untuk membuka layar hitung mundur darurat saat layar terkunci |
| Notifikasi (Android 13+, `POST_NOTIFICATIONS`) | Saat Monitoring dimulai, tanpa memblokir | Ya untuk notifikasi permanen foreground service; untuk alert darurat opsional (SMS tetap disiapkan jika ditolak) |
| Lokasi (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) | Saat insiden | Tidak; tanpa lokasi insiden disimpan tanpa lokasi |

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
- SMS memerlukan penekanan tombol kirim oleh pengguna
- Satu kontak darurat
- Penghapusan yang gagal dikirim ke server dapat muncul kembali saat sinkronisasi
