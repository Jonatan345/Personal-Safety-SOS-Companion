# P12 — Keamanan dan Privasi

## 01 · Identifikasi risiko: Log aplikasi

| Aspek | Isi |
| --- | --- |
| Risiko | Log aplikasi dapat memuat data pribadi (koordinat lokasi, waktu insiden) |
| Fitur | Log Aplikasi (P10): `AppLogger` mencatat alur insiden, penyimpanan, dan sinkronisasi; layar Log Aplikasi dapat menyalin log |
| Pemicu | (1) Terjadi error saat memproses atau membaca catatan insiden. (2) Pengguna menekan **Salin log** dan menempelkannya ke aplikasi lain. |
| Data terpapar | Teks error mentah yang menyertakan potongan isi catatan insiden: koordinat GPS, waktu, status. Pola kapan insiden terjadi. |
| Akses terpapar | Layar log tanpa kunci (siapa pun yang memegang HP terbuka dapat membukanya); log tersimpan permanen di Hive (maks. 300 entri); hasil salin masuk clipboard dan pesan yang dikirim. |
| Bukti | Hasil test: `Melewati catatan insiden rusak: FormatException: Unexpected character (at character 2) {bukan-json` — pesan error menyalin isi catatan. Pada catatan nyata, potongan itu dapat berisi latitude dan longitude. |
| Dampak | Lokasi dan kebiasaan pengguna aplikasi keselamatan bisa bocor lewat log yang dikirim atau terbaca. |
| Rencana perbaikan | Catat hanya kode kejadian dan status (tanpa isi data), saring teks error sebelum disimpan, dan beri peringatan sebelum menyalin log. |

## 02 · Perbaikan

- `AppLogger` tidak lagi menyimpan teks exception atau stack trace. Untuk kegagalan, log hanya menyimpan pesan kejadian dan status berupa tipe error, misalnya `[status: FormatException]`.
- Kegagalan saat memuat penyimpanan permanen juga tidak menulis detail error ke keluaran debug.
- Tombol **Salin log** sekarang menampilkan dialog konfirmasi yang mengingatkan pengguna bahwa log masuk clipboard dan harus ditinjau sebelum dibagikan.

## 03 · Bukti hasil

Jalankan:

```powershell
flutter test test/app_logger_test.dart test/log_screen_test.dart
```

Test `does not record incident JSON or location from an exception` memberi error berisi JSON dengan `latitude` dan `longitude`, lalu membuktikan keduanya tidak muncul pada entri maupun teks ekspor. Test layar log membuktikan clipboard masih kosong sampai pengguna menekan **Salin log** pada dialog konfirmasi.

Untuk bukti visual, jalankan aplikasi, buka **Log Aplikasi** dari ikon serangga di beranda, lalu ambil screenshot entri kegagalan yang hanya menampilkan status (contoh: `[status: FormatException]`) dan dialog konfirmasi **Salin log aplikasi?**. Jangan gunakan screenshot yang memuat data insiden asli.
