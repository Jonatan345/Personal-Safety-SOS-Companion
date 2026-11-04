# P9 — Test dan Refactor

Fokus: memastikan perilaku kritis terlindungi test, memisahkan tanggung jawab
menjadi fungsi/kelas kecil, dan menghapus duplikasi. Fitur yang dijadikan
contoh adalah **form Kontak Darurat** (padanan "ProfileForm" di slide).

## Pemisahan tanggung jawab

| Tanggung jawab | Sebelum | Sesudah |
| --- | --- | --- |
| Input dan status UI (ProfileForm) | `_ContactForm` privat di dalam `contact_setup_screen.dart` (±400 baris) | `lib/widgets/contact_form.dart` (`ContactForm`) dan `lib/widgets/contact_cards.dart` |
| Aturan input (validation) | `_validatePhoneNumber` dan validator nama tertanam di widget | `lib/validation/contact_validation.dart`: `validateContactName`, `validateContactPhone` (fungsi murni) |
| Akses data (profileRepository) | JSON dirakit manual di repository | `EmergencyContact.fromJson/toJson` + `EmergencyContactRepository` (Hive); `IncidentRepository` (Hive + REST) |
| Hasil simpan | Layar menebak sukses dari `hasContact` | `ContactSaveResult { saved, failed, alreadySaving }` dari notifier |
| Alur insiden | Satu fungsi ±100 baris di `IncidentScreen` | `lib/use_cases/incident_reporter.dart`: `report()` dan `dispatch()` memanggil langkah kecil `_tryLocate`, `_trySave`, `_tryLoadContact` |
| Riwayat | Satu berkas ±440 baris | `history_screen.dart` (tampilan), `history_actions.dart` (tindakan), `incident_tile.dart`, `sync_banner.dart`, `incident_detail_sheet.dart` |

Layar hanya merangkai state dan widget. Layar tidak lagi berisi aturan input,
perakitan JSON, atau urutan langkah alert.

## Duplikasi yang dihapus

- Pola mutasi daftar (ubah/hapus) di `IncidentNotifier` → satu `_mutateExisting`.
- Pola "kirim ke server, kegagalan hanya dicatat" di `IncidentRepository` → satu `_mirrorToServer`; penulisan ke Hive → satu `_put`.
- Validasi koordinat latitude/longitude di `Incident.fromJson` → satu `_coordinate`.
- Pembuatan SnackBar di empat layar → satu `showMessage` (`utils/snackbars.dart`).
- Pembuatan JSON kontak (kunci ditulis dua kali) → `EmergencyContact.toJson/fromJson`.
- Test: fake repository, fake alert, pembuat insiden, dan pengatur ukuran layar yang tadinya ditulis ulang di tiap berkas test kini ada satu kali di `test/support/`.

Angka dan nama yang tersebar sebelumnya juga sudah satu sumber: `SosConfig`,
`IncidentStatus`, `LocalStorageService` (nama box), `AppRoutes`.

## Kontrak perilaku form (tabel dari slide)

| Kasus | Hasil yang diharapkan | Test |
| --- | --- | --- |
| Nama hanya spasi | Pesan "Nama wajib diisi"; repository tidak dipanggil | `kontrak perilaku form (P9)` → *a name made only of spaces is rejected before any request*; `validation/contact_validation_test.dart` |
| Simpan sedang berjalan | Tombol nonaktif; hanya satu request | `kondisi UI wajib (P4)` → *shows submit loading and prevents a double submit* |
| Simpan gagal | Pesan gagal; input tetap; bisa mencoba lagi | *a failed save explains why, keeps the input and can retry* |
| Simpan berhasil | Pesan "Kontak darurat berhasil disimpan" dan kartu kontak | *a successful save shows the confirmation and the contact* |
| Lebar layar berubah | Layout menyesuaikan; nilai input bertahan | *typed values survive a change of screen width*, grup P8 |
| Mengubah kontak yang sudah ada lalu gagal | Tidak ditampilkan sebagai sukses | *a failed edit of an existing contact is not shown as success* |

Test kritis lain: alur insiden (`incident_reporter_test.dart`,
`incident_screen_test.dart`), penyimpanan dan sinkronisasi
(`incident_repository_test.dart`, `incident_notifier_test.dart`), API
(`incident_api_test.dart`, `incident_api_failure_test.dart`), riwayat
(`history_screen_test.dart`), dan Home (`home_screen_test.dart`).

## Langkah refactor (satu bagian per langkah)

1. Jalankan `flutter test`; semua lulus (tes awal).
2. Pindahkan **validasi** ke `validation/contact_validation.dart`; widget memanggil fungsi itu.
3. Jalankan `flutter test` lagi; commit.
4. Pindahkan **form** ke `ContactForm`; jalankan test; commit.
5. Pindahkan **alur insiden** ke `IncidentReporter`; jalankan test; commit.
6. Hapus duplikasi (notifier, repository, snackbar, fake test); jalankan test; commit.

## Demo: merusak satu aturan dengan sengaja

1. Di `lib/validation/contact_validation.dart` ubah `raw.trim().isEmpty` menjadi `raw.isEmpty`.
2. Jalankan `flutter test test/validation/contact_validation_test.dart`: test nama spasi gagal.
3. Jalankan `flutter test test/contact_setup_screen_test.dart`: test *a name made only of spaces…* gagal karena repository terpanggil.
4. Kembalikan perubahan; semua test lulus lagi.

## Hasil dokumentasi demo yang merusak satu aturan dengan sengaja
Link Yt: https://youtu.be/7Zo_haBcjqk

## Cara memeriksa sebelum commit

```powershell
flutter analyze
flutter test
node --test backend/server.test.mjs
```

Semua harus lulus tanpa error. Riwayat bug yang ditemukan dan test regresinya
ada di `bug-log.md`.
