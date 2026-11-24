# Release Notes — SOS Companion v1.0.0 (RC1)

Versi: `1.0.0+1` · tag: `v1.0.0-rc.1` · platform: Android (APK)

## Fitur
- Deteksi jatuh/guncangan (accelerometer) dan suara keras (mikrofon)
- Hitung mundur 10 detik dengan pembatalan (tombol dan tombol kembali sistem)
- Lokasi GPS saat insiden; bila gagal, insiden disimpan tanpa lokasi dan pengguna diberi tahu
- Satu kontak darurat dengan validasi; kesiapan SOS tampil di beranda
- Notifikasi dan SMS composer berisi tautan peta jika lokasi ada
- Riwayat insiden lokal: detail, ubah catatan, hapus dengan konfirmasi dan urungkan
- Sinkronisasi opsional ke backend demo
- Layout adaptif, aman untuk keyboard, mendukung pembaca layar dan teks 200%

## Baru di RC1
- **Log aplikasi** (Beranda → ikon serangga): mencatat start aplikasi, sensor, insiden, sinkronisasi, dan semua error yang tidak tertangani; bisa disalin dan dikirim ke pengembang. Log tetap ada setelah aplikasi ditutup (maksimum 300 entri).
- Penandatanganan APK rilis dengan keystore (`android/key.properties`).
- Aturan ProGuard untuk notifikasi pada build rilis.

## Masalah yang diketahui
- Monitoring hanya berjalan saat aplikasi terbuka di layar (tanpa foreground service).
- SMS tidak terkirim otomatis: pengguna menekan kirim di aplikasi SMS.
- Backend sinkronisasi hanya demo (tanpa autentikasi, HTTP hanya pada build debug).
- Penghapusan yang gagal dikirim ke server dapat muncul kembali saat sinkronisasi.
- `applicationId` masih `com.example.sos_companion`: harus diganti sebelum publikasi ke Play Store.
