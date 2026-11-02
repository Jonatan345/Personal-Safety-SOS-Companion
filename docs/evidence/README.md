# Bukti (Evidence)

## P4 — alur Kontak Darurat

Berkas bukti visual: `p4-contact-flow.png` **atau** `p4-contact-flow.mp4`
(screenshot atau rekaman 10–20 detik dari HP). Langkah pengambilan ada di
`../p4-state-management.md`.

Bukti otomatis: `../p4-state-management.md` dan
`../../test/contact_setup_screen_test.dart`.

## P5 — Local Data & Persistence

Video CRUD dan persistence: <https://youtu.be/JmwPUNWhOu0>

Test otomatis: `../../test/incident_repository_test.dart` (create, read,
update, delete, data tetap ada setelah box ditutup dan dibuka lagi, catatan
rusak dilewati).

## P6 — Integrasi API

Test otomatis: `../../test/incident_api_test.dart`,
`../../test/incident_api_failure_test.dart` (timeout, error jaringan, HTTP,
JSON rusak, pesan Bahasa Indonesia), dan bagian sinkronisasi di
`../../test/incident_repository_test.dart`.

## P8 — Responsive UX

Screenshot form Kontak Darurat pada 360 × 800 dan 800 × 1280:

- `p8-mobile-keyboard-closed.png`
- `p8-mobile-keyboard-open.png`
- `p8-wide-keyboard-closed.png`
- `p8-wide-keyboard-open.png`

Catatan: varian keyboard terbuka diambil di browser desktop, yang tidak
menampilkan keyboard layar HP. Untuk bukti yang lebih kuat, ambil ulang
screenshot dari HP asli (keyboard benar-benar tampil) dan ganti berkas di atas.

Test otomatis: `../../test/contact_setup_screen_test.dart` (layout, resize,
inset keyboard, teks 200%, feedback simpan) dan `../../test/home_screen_test.dart`
(tanpa overflow pada dua ukuran layar dan teks 200%, label pembaca layar).
