# Architecture — SOS Companion

## Stack
- Flutter / Dart, Material 3
- State management: Riverpod (`StateNotifier` dan `AsyncNotifier`)
- Penyimpanan lokal: Hive (JSON string pada box ber-versi)
- Sensor dan perangkat: `sensors_plus` (accelerometer), `noise_meter`
  (level mikrofon), `geolocator` (GPS), `permission_handler`,
  `flutter_local_notifications`, `url_launcher` (SMS composer)
- Opsional: REST backend `backend/server.mjs` (Node.js, hanya demo)

## Struktur repository
```text
Personal-Safety-SOS-Companion/
├── android/ ios/ web/ linux/ macos/ windows/   # platform runner
├── backend/
│   ├── server.mjs               # REST API demo (tanpa auth, penggunaan lokal)
│   └── server.test.mjs
├── docs/                        # scope, P4, P9, bug-log, evidence
├── lib/
│   ├── main.dart                # entry point, ProviderScope
│   ├── models/                  # Incident, IncidentStatus, EmergencyContact
│   ├── notifiers/               # state Riverpod (insiden, kontak darurat)
│   ├── repositories/            # akses data (Hive, REST)
│   ├── routes/app_routes.dart   # nama rute (satu-satunya sumber)
│   ├── screens/                 # home, monitoring, incident, history (+ actions), contact setup
│   ├── services/                # sensor, lokasi, izin, alert, API, penyimpanan
│   ├── theme/app_theme.dart
│   ├── use_cases/               # kontak darurat load/save, IncidentReporter
│   ├── utils/                   # SosConfig, formatters, error_messages, snackbars, sos_message
│   ├── validation/              # aturan input (fungsi murni)
│   └── widgets/                 # AppCard, PrimaryButton, ContactForm, IncidentTile, SyncBanner, ...
├── test/
│   ├── support/                 # fake dan helper bersama (fakes.dart, pump.dart)
│   ├── validation/              # test aturan input
│   └── *.dart                   # test widget, notifier, repository, API, use case
├── pubspec.yaml
└── README.md
```

## Lapisan dan tanggung jawab
```text
Screen (UI)  ->  Notifier (state)  ->  Use case / Repository  ->  Hive / REST
```
| Lapisan | Tugas | Contoh |
| --- | --- | --- |
| Widget | Menampilkan input dan status | `ContactForm`, `IncidentTile` |
| Validation | Aturan input, fungsi murni | `validateContactPhone` |
| Notifier | State dan hasil aksi | `EmergencyContactNotifier.save` → `ContactSaveResult` |
| Use case | Urutan langkah bisnis | `IncidentReporter` (lokasi → simpan → kontak → alert) |
| Repository | Membaca/menulis data | `IncidentRepository`, `HiveEmergencyContactRepository` |

Layar tidak menyentuh Hive secara langsung. Layanan yang memakai platform
berada di balik antarmuka kecil (`MonitoringController`, `AlertGateway`,
`EmergencyContactRepository`) sehingga test bisa menggantinya.

## Alur runtime
1. **Monitoring** meminta izin mikrofon (satu-satunya prasyarat), lalu memulai
   accelerometer (≥ `SosConfig.accelerationThreshold`) dan mikrofon
   (≥ `SosConfig.soundThresholdDb`). Izin notifikasi diminta tanpa memblokir.
   Izin dan start sensor punya batas waktu dan tombol coba lagi.
2. Trigger membuka layar **Insiden**: hitung mundur `SosConfig.countdownSeconds`.
   Batal lewat tombol atau tombol kembali sistem dicatat sebagai `cancelled`.
3. Saat hitung mundur selesai, `IncidentReporter.report('sent')`: waktu dicatat,
   GPS dibaca (gagal → lokasi `null`), insiden disimpan, kontak dimuat.
4. App membuka **Riwayat**; `IncidentReporter.dispatch` menampilkan notifikasi
   lalu membuka SMS composer (tautan peta hanya jika lokasi ada). Setiap
   kegagalan tampil sebagai pesan Bahasa Indonesia.
5. Setelah layar insiden ditutup, monitoring tetap bekerja.

## Data
- `Incident`: id, timestamp, latitude/longitude nullable, status
  (`IncidentStatus`). Box `incidents_v2`.
- `EmergencyContact`: id, name, phoneNumber. Box `emergency_contacts_v2`.
- Sinkronisasi (opsional, `--dart-define=API_BASE_URL=...`): Riwayat memuat data
  lokal dulu, lalu `syncFromServer` menggabungkan dengan backend. Perangkat
  adalah sumber utama; kegagalan server menampilkan banner dan data lokal tetap.

## Satu sumber untuk konstanta
`SosConfig` (ambang, hitung mundur), `IncidentStatus` (nilai status),
`LocalStorageService` (nama box), `AppRoutes` (nama rute).

## Batasan
- Monitoring hanya berjalan saat aplikasi terbuka di layar.
- SMS composer memerlukan pengguna menekan kirim.
- Build rilis memblokir HTTP; build debug mengizinkannya untuk backend lokal.
- Penghapusan yang gagal dikirim ke server dapat muncul kembali saat sinkronisasi.
