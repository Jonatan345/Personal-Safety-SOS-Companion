# Project Scope — SOS Companion

## Problem Statement
Pengguna yang bepergian sendirian tidak punya cara cepat memberi tahu kontak
darurat saat terjatuh, mengalami kecelakaan, atau merasa tidak aman.

## Target User
Mahasiswa dan individu yang sering bepergian atau berjalan sendirian.

## Nilai Aplikasi
Mendeteksi kemungkinan insiden (gerakan jatuh/guncangan atau suara keras),
mengambil lokasi, dan menyiapkan alert ke kontak darurat tanpa menekan nomor
secara manual.

## In Scope
- Deteksi jatuh/guncangan dengan accelerometer
- Ambang level suara mikrofon sebagai pemicu kedua
- Hitung mundur dengan pembatalan untuk menghindari alarm palsu
- Lokasi GPS saat insiden; jika gagal, insiden disimpan tanpa lokasi dan
  pengguna diberi tahu alasannya
- Riwayat insiden lokal (Hive): buat, baca, ubah catatan, hapus (dengan
  konfirmasi dan urungkan)
- Satu kontak darurat dengan validasi input
- Notifikasi perangkat dan SMS composer berisi tautan peta jika lokasi ada
  (pengguna menekan kirim)
- Izin runtime: mikrofon (wajib untuk monitoring), notifikasi (tanpa
  memblokir), lokasi (saat insiden)
- Sinkronisasi opsional ke backend demo (`API_BASE_URL`)

## Out of Scope
- Banyak kontak darurat
- Akun pengguna dan backend produksi (backend Node.js hanya demo tanpa autentikasi)
- Monitoring saat aplikasi ditutup atau layar terkunci (tanpa foreground service)
- Pengiriman SMS otomatis tanpa konfirmasi pengguna
- Pengenalan suara (hanya ambang level suara)
- Integrasi wearable
