# P7 — Perbaikan hasil review dosen

## 1. Izin notifikasi tidak pernah diminta
- `PermissionService.requestNotificationPermission()` memakai `Permission.notification` (Android 13+), dengan timeout 12 detik dan tidak pernah melempar error.
- Dipanggil dari `MonitoringScreen` setelah mikrofon diizinkan. Tidak memblokir sensor: mikrofon tetap satu-satunya prasyarat monitoring.
- Jika ditolak: SnackBar menjelaskan dampaknya (SMS tetap disiapkan). Jika diblokir permanen: tombol **Pengaturan**.
- `AlertService.showEmergencyNotification` memeriksa izin sebelum `show`, dan mengembalikan alasan gagal (bukan menelan error dengan `.catchError((_) {})`). Alasan itu tampil ke pengguna lewat SnackBar.

## 2. Lokasi gagal menjadi 0,0
- `Incident.latitude/longitude` kini `double?`. GPS mati / izin ditolak / timeout menyimpan `null`.
- `buildSosMessage` tidak membuat tautan peta tanpa koordinat; SMS berisi "Lokasi saya tidak tersedia".
- Pengguna diberi tahu alasannya (mis. "Layanan lokasi perangkat sedang nonaktif. Alert tetap dikirim tanpa lokasi.").
- Riwayat menampilkan "Lokasi tidak tersedia" / "Lokasi tidak diambil (dibatalkan)". Data lama 0,0 diperlakukan sebagai tidak ada lokasi.
- Backend menerima `null` hanya jika kedua koordinat null.

## Bukti uji
Otomatis: `test/incident_screen_test.dart`, `test/incident_location_test.dart`, `backend/server.test.mjs`.

Manual (HP Android 13+):
| Skenario | Hasil yang diharapkan |
|---|---|
| Install baru, buka Monitoring | Dialog mikrofon, lalu dialog notifikasi |
| Tolak notifikasi | SnackBar penjelasan; monitoring tetap aktif |
| Matikan GPS, picu insiden | Riwayat "Lokasi tidak tersedia"; SMS tanpa tautan peta; SnackBar alasan |
| GPS aktif, picu insiden | Riwayat berisi koordinat; SMS berisi tautan peta |
