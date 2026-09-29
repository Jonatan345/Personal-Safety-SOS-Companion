# P4 — Emergency Contact State Management

## Tujuan Feature

Feature **Kontak Darurat** menerapkan form dan state management nyata dengan
Riverpod. Pada P4, repository masih in-memory agar fokus tugas berada pada
state UI, validasi, dan pemisahan tanggung jawab. Penyimpanan permanen dengan
Hive dijadwalkan untuk P5.

## Arsitektur

```text
ContactSetupScreen (widget/UI)
  → EmergencyContactNotifier (Riverpod state controller)
  → Load/SaveEmergencyContactUseCase (business action)
  → EmergencyContactRepository (data abstraction)
  → InMemoryEmergencyContactRepository (temporary P4 implementation)
```

Lokasi kode:

- `lib/screens/contact_setup_screen.dart` — UI dan form.
- `lib/notifiers/emergency_contact_notifier.dart` — state loading, data,
  empty, error, retry, dan submit.
- `lib/use_cases/emergency_contact_use_cases.dart` — use case load/save.
- `lib/repositories/emergency_contact_repository.dart` — kontrak repository
  dan implementasi in-memory.
- `lib/models/emergency_contact.dart` — entity dan data input.

## Enam Kondisi UI Wajib

| Kondisi | Tampilan | Test |
| --- | --- | --- |
| Initial loading | `CircularProgressIndicator` ketika repository memuat data | `shows initial loading while contact data is fetched` |
| Data berhasil dimuat | Kartu nama dan nomor kontak aktif | `shows loaded data when a contact exists` |
| Empty state | Pesan belum ada kontak dan tombol tambah | `shows empty state when no contact has been saved` |
| Error + retry | Pesan gagal memuat dan tombol `Coba lagi` | `shows error state and retry loads the contact again` |
| Validasi form | Nama wajib diisi; nomor minimal 3 digit dan format nomor valid | `validates required name and short phone number` |
| Loading submit | Tombol menjadi loading/disabled saat save sehingga tidak double tap | `shows submit loading and prevents a double submit` |

## Hasil Verifikasi

Perintah yang dijalankan:

```powershell
flutter test test/contact_setup_screen_test.dart
```

Hasil pada 29 September 2026:

```text
00:02 +6: All tests passed!
```

## Bukti Visual yang Dikumpulkan

Saat demo, ambil screenshot atau video singkat (10–20 detik) dengan urutan:

1. Buka **Kontak Darurat** dan tunjukkan empty state.
2. Tekan **Tambah Kontak Darurat**, lalu tekan **Simpan Kontak** tanpa input
   untuk menunjukkan validasi.
3. Isi `Ibu Sari` dan `911`, tekan simpan, lalu rekam loading pada tombol.
4. Tunjukkan kartu data kontak yang berhasil dimuat.

Simpan bukti sebagai `docs/evidence/p4-contact-flow.png` atau
`docs/evidence/p4-contact-flow.mp4` sebelum pengumpulan. Error state dan
retry telah dibuktikan secara terisolasi oleh widget test melalui repository
yang mengembalikan error.
