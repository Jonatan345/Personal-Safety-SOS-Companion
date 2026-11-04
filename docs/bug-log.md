# Bug Log

Setiap bug yang ditemukan selama P4–P9, penyebabnya, perbaikannya, dan test
regresi yang menjaganya.

| ID | Ditemukan | Gejala | Penyebab | Perbaikan | Test regresi |
| --- | --- | --- | --- | --- | --- |
| B01 | P7 | Notifikasi tidak muncul di Android 13+ | Izin notifikasi tidak pernah diminta saat runtime | `PermissionService.requestNotificationPermission` dipanggil saat Monitoring dimulai tanpa memblokir sensor | `incident_location_test.dart` (izin notifikasi), `monitoring_screen_test.dart` |
| B02 | P7 | SMS berisi tautan peta ke 0,0 saat GPS gagal | Koordinat default 0.0 | Lokasi disimpan `null`; SMS tanpa tautan; pengguna diberi alasan | `incident_reporter_test.dart` (GPS failure), `incident_screen_test.dart`, `incident_repository_test.dart` |
| B03 | Audit | Monitoring berhenti mendeteksi setelah insiden pertama | `_triggerHandled` tidak pernah di-reset | Di-reset saat layar insiden ditutup | `monitoring_screen_test.dart` (*monitoring still detects a new incident…*) |
| B04 | Audit | Label tombol "Batalkan" tidak terbaca | Teks putih di tombol putih | Parameter `foregroundColor` pada `PrimaryButton` | `incident_screen_test.dart` (*cancel button label is readable…*) |
| B05 | Audit | Riwayat hanya menampilkan insiden baru | `addIncident` saat daftar masih loading membuang data lama | Daftar dibaca ulang dari penyimpanan | `incident_notifier_test.dart` |
| B06 | Audit | Seluruh riwayat gagal dimuat | Satu catatan Hive rusak melempar error | Catatan rusak dilewati | `incident_repository_test.dart` |
| B07 | Audit | Alert tidak terkirim jika penyimpanan gagal | Penyimpanan dan alert satu rantai | `IncidentReporter._trySave` tidak melempar; alert lanjut | `incident_reporter_test.dart`, `incident_screen_test.dart` |
| B08 | P9 | Gagal mengubah kontak tampil seperti sukses | Layar menebak sukses dari `hasContact` (kontak lama masih ada) | `ContactSaveResult` dari notifier | `contact_setup_screen_test.dart` (*a failed edit… not shown as success*) |
| B09 | P9 | Waktu insiden meleset hingga belasan detik | Timestamp dibuat setelah menunggu GPS | Waktu dicatat sebelum GPS | `incident_reporter_test.dart` (*incident time…*) |
| B10 | P9 | Tombol kembali sistem menghapus insiden tanpa jejak | Timer dibatalkan saat layar ditutup | `PopScope`: kembali = dibatalkan dan dicatat | `incident_screen_test.dart` (*system back button…*) |
| B11 | Audit | Status riwayat berubah karena ketukan tidak sengaja; hapus tanpa konfirmasi | Ketuk = toggle; geser = hapus | Detail dengan tombol eksplisit, dialog konfirmasi, tombol Urungkan | `history_screen_test.dart` |
| B12 | Audit | Pesan error Inggris/mentah tampil ke pengguna | `$error` dicetak langsung | `userMessageFor` (Bahasa Indonesia) | `incident_api_failure_test.dart` |
| B13 | P6 | Aplikasi tidak pernah memuat dari backend | `IncidentRepository` hanya membaca Hive | `syncFromServer` + banner status sinkronisasi | `incident_repository_test.dart`, `incident_notifier_test.dart`, `history_screen_test.dart` |
| B14 | P9 | Perubahan status lokal tidak sampai ke server | Sinkronisasi hanya mengirim insiden baru | Status berbeda dikirim sebagai PATCH | `incident_repository_test.dart` (*status yang berbeda…*) |
| B15 | Audit | Layar insiden terpotong di landscape/teks besar; hitung mundur tidak diumumkan | Kolom tanpa scroll; tanpa live region | Scroll + `Semantics(liveRegion)` | `incident_screen_test.dart` (*short landscape…*) |
| B16 | P9 | Home selalu menulis "Nonaktif" | Teks statis, bukan data nyata | Kesiapan dibaca dari kontak darurat tersimpan | `home_screen_test.dart` |
| B17 | P9 | Tombol simulasi tampil di APK rilis | Tombol uji selalu dibuat | Hanya tampil jika `!kReleaseMode` | Diperiksa dengan build rilis (`flutter build apk --release`) |
