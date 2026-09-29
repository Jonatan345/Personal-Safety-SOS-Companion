# AI Usage Record — P4

## Tool

Codex (AI coding assistant) digunakan untuk membantu membuat boilerplate,
test widget, dan meninjau struktur feature.

## Prompt yang Digunakan

> Sekarang kita masuk ke P4 tambahkan yang perlu ditambahkan di P4 ini dengan
> notes: Tugas Anda adalah membuat satu feature Flutter yang menerapkan state
> management, form, dan validasi secara nyata. Feature wajib memiliki minimal
> enam kondisi UI: initial loading, data berhasil dimuat, empty state, error
> state dengan tombol retry, validasi input pada form, serta loading saat
> proses submit agar pengguna tidak dapat melakukan double tap. Gunakan state
> management yang konsisten, misalnya Riverpod, dan pisahkan tanggung jawab
> antara widget, notifier/use case, serta repository. Sertakan widget test
> untuk setiap state utama dan dokumentasikan hasilnya dengan screenshot atau
> video singkat. Anda boleh menggunakan Codex atau Gemini untuk membantu
> membuat boilerplate, test, atau melakukan review kode, tetapi Anda tetap
> wajib memahami, menjelaskan, dan bertanggung jawab atas kode yang
> dikumpulkan; cantumkan prompt AI yang digunakan serta bagian kode yang Anda
> periksa atau perbaiki sendiri.

## Bagian yang Ditinjau dan Diperbaiki Sendiri

- Memilih feature Kontak Darurat karena sesuai alur aplikasi SOS Companion.
- Memeriksa bahwa repository P4 memakai memori saja; Hive tidak dipakai lebih
  awal karena penyimpanan lokal adalah target P5.
- Memeriksa validasi nomor agar menerima nomor darurat pendek seperti `911`
  dan `112`, serta nomor internasional berformat `+1 555 123 4567`.
- Memperbaiki test double-submit: setelah tombol masuk loading, teks tombol
  memang tidak lagi tampil. Test kemudian memeriksa `onPressed == null` pada
  `ElevatedButton`, yang membuktikan tombol disabled secara benar.
- Menjalankan ulang widget test sampai semua enam test lulus.

## Tanggung Jawab Mahasiswa

Mahasiswa perlu dapat menjelaskan alur `Widget → Notifier → Use Case →
Repository`, alasan memakai `ProviderScope`, serta mengapa loading submit
menonaktifkan tombol untuk mencegah dua request penyimpanan.
