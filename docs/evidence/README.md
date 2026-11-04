# Bukti (Evidence)

## P4 — alur Kontak Darurat
Screenshot atau rekaman 10–20 detik dari HP: `p4-contact-flow.png` atau
`p4-contact-flow.mp4`. Urutan pengambilan ada di `../p4-state-management.md`.

Bukti otomatis: `../../test/contact_setup_screen_test.dart`.

## P5 — Local Data & Persistence
Video CRUD dan persistence: <https://youtu.be/JmwPUNWhOu0>

Test otomatis: `../../test/incident_repository_test.dart` (buat, baca, ubah,
hapus, data tetap ada setelah box ditutup dan dibuka lagi, catatan rusak
dilewati) dan `../../test/emergency_contact_repository_test.dart`.

## P6 — Integrasi API
Test otomatis: `../../test/incident_api_test.dart`,
`../../test/incident_api_failure_test.dart` (timeout, error jaringan, HTTP,
JSON rusak, pesan Bahasa Indonesia), dan bagian sinkronisasi di
`../../test/incident_repository_test.dart`. Backend: `node --test
backend/server.test.mjs`.

## P8 — Responsive UX
Screenshot form Kontak Darurat pada 360 × 800 dan 800 × 1280:

- `p8-mobile-keyboard-closed.png`
- `p8-mobile-keyboard-open.png`
- `p8-wide-keyboard-closed.png`
- `p8-wide-keyboard-open.png`

Varian keyboard terbuka diambil di browser desktop, yang tidak menampilkan
keyboard layar HP. Untuk bukti yang lebih kuat, ambil ulang dari HP asli.

Test otomatis: `../../test/contact_setup_screen_test.dart` (layout, keyboard,
teks 200%), `../../test/home_screen_test.dart`, dan
`../../test/incident_screen_test.dart` (landscape dan teks 200%).

## P9 — Test dan Refactor
Penjelasan refactor, kontrak perilaku, dan demo merusak satu aturan:
`../p9-test-refactor.md`. Bug yang ditemukan dan test regresinya:
`../bug-log.md`.
