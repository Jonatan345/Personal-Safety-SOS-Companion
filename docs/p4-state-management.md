# P4 — Emergency Contact State Management

## Tujuan Feature

Feature **Kontak Darurat** menerapkan form dan state management dengan
Riverpod. Implementasi awal P4 menggunakan repository in-memory; repository
saat ini memakai Hive agar kontak tetap tersedia setelah aplikasi dibuka
kembali.

Feature kedua yang memakai Riverpod adalah **Riwayat Insiden**
(`IncidentNotifier`): loading, kosong, error + retry, data, dan status
sinkronisasi dengan backend. Test-nya ada di `test/history_screen_test.dart`
dan `test/incident_notifier_test.dart`.

## Arsitektur

```text
ContactSetupScreen (widget/UI)
  → EmergencyContactNotifier (Riverpod state controller)
  → Load/SaveEmergencyContactUseCase (business action)
  → EmergencyContactRepository (data abstraction)
  → HiveEmergencyContactRepository (local persistent storage)
```

Lokasi kode:

- `lib/screens/contact_setup_screen.dart` — UI dan form.
- `lib/notifiers/emergency_contact_notifier.dart` — state loading, data,
  empty, error, retry, dan submit.
- `lib/use_cases/emergency_contact_use_cases.dart` — use case load/save.
- `lib/repositories/emergency_contact_repository.dart` — kontrak repository
  dan implementasi Hive.
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

`test/contact_setup_screen_test.dart` berisi **81 test** (tata letak layar sempit dan
lebar, keyboard aktif, teks 200%, dan feedback gagal simpan).

Hasil ketika semua test lulus:

```text
+81: All tests passed!
```

(2026-11-02) 00:12 +39: C:/projects/Personal-Safety-SOS-Companion/test/incident_repository_test.dart: a corrupted record is skipped instead of failing the whole history
Melewati catatan insiden rusak: FormatException: Unexpected character (at character 2)
{bukan-json
 ^

(2026-11-02) 00:12 +48: C:/projects/Personal-Safety-SOS-Companion/test/incident_repository_test.dart: sinkronisasi dengan server server tidak dapat dihubungi: error Indonesia, data lokal utuh
Sinkronisasi insiden ke server gagal: IncidentApiException: Unable to connect to the incidents API.
(2026-11-02) 00:18 +81: All tests passed! 

## Bukti Visual yang Dikumpulkan

Ambil screenshot atau video singkat (10–20 detik) dari HP dengan urutan:

1. Buka **Kontak Darurat** dan tunjukkan empty state.
2. Tekan **Tambah Kontak Darurat**, lalu tekan **Simpan Kontak** tanpa input
   untuk menunjukkan validasi.
3. Isi `Ibu Sari` dan `911`, tekan simpan, lalu rekam loading pada tombol.
4. Tunjukkan kartu data kontak yang berhasil dimuat.

Simpan sebagai `docs/evidence/p4-contact-flow.png` atau
`docs/evidence/p4-contact-flow.mp4` lalu commit. Error state dan retry
dibuktikan secara terisolasi oleh widget test melalui repository yang
mengembalikan error.
