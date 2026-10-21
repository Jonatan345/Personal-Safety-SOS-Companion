# Personal-Safety-SOS-Companion
Using phone's built-in sensor APIs together (not one sensor alone), handling permissions for each, and combining their data into one logic.

## Problem Statement
Solo commuters/students lack a quick way to alert emergency contacts
when they fall, get into an accident, or feel unsafe while alone.

## Target User
Students/individuals who frequently travel or walk alone.

## App Value
Automatically detects potential incidents (fall/shake) and sends
location + alert to emergency contact without manual dialing.

## MVP P7: fitur yang dapat didemokan
- **Sensor**: accelerometer memicu alarm ketika percepatan melewati ambang shake/fall; mikrofon membaca amplitudo lingkungan dan memicu alarm pada 85 dB.
- **Lokasi**: setelah countdown habis, aplikasi mengambil GPS berakurasi tinggi dan menyimpan koordinat pada riwayat lokal Hive.
- **Notifikasi dan SMS**: notifikasi perangkat mengonfirmasi alert. Bila kontak tersedia, aplikasi membuka SMS composer perangkat dengan tautan Google Maps agar pengguna tetap memberi persetujuan akhir sebelum SMS dikirim.
- **Izin dan state**: izin lokasi, mikrofon, dan notifikasi diminta sebelum monitoring dimulai; penolakan menampilkan pesan serta tombol coba lagi. Loading, empty, error, retry, dan pembatalan countdown juga tersedia.

### Demo vertical slice
1. Tambahkan satu kontak darurat dari **Kontak Darurat**.
2. Ketuk **Mulai Monitoring** dan izinkan lokasi, mikrofon, serta notifikasi.
3. Goyangkan perangkat kuat-kuat atau ketuk **Simulasikan Shake/Fall**.
4. Biarkan countdown sepuluh detik selesai: GPS diambil, insiden tersimpan di Hive, notifikasi muncul, lalu SMS composer terbuka dengan lokasi.
5. Periksa **Riwayat**. Gunakan tombol pembatalan sebelum countdown habis untuk mencatat insiden sebagai dibatalkan tanpa mengambil lokasi atau membuka SMS.

## Must-Have Features
- Real-time accelerometer-based fall/shake detection
- GPS location capture triggered on incident
- Countdown screen with cancel option (avoid false alarm)
- Emergency contact input & validation
- SMS/notification alert sent automatically to emergency contact
- Incident history stored locally in Hive (time, location, status); REST sync is optional for the older P6 demo backend
- Permission handling (location, sensors, microphone)
- Loading, empty, and error states on all screens
- Microphone amplitude threshold as secondary trigger
  
## In Scope
- Accelerometer-based fall/shake detection
- GPS location capture on trigger
- Microphone amplitude threshold as secondary trigger
- Countdown + cancel (avoid false alarm)
- Local incident history log
- SMS/notification alert to 1 emergency contact

## Out of Scope
- Multiple emergency contacts
- Multi-user accounts
- Real speech recognition (only amplitude threshold)
- Wearable device integration

## Success Criteria
- Aplikasi berhasil mendeteksi shake/fall pattern via accelerometer
- GPS location berhasil diambil otomatis saat incident terdeteksi
- Countdown + cancel berfungsi (tidak trigger alert jika dibatalkan)
- Alert/notifikasi berhasil terkirim ke emergency contact
- Riwayat insiden tersimpan dan dimuat secara lokal, termasuk saat backend tidak aktif
- Semua permission (lokasi, sensor, mic) ditangani dengan benar
- APK dapat diinstal dan didemokan end-to-end tanpa crash

## User Flow
1. Home Screen → user set emergency contact (first time only)
2. User tap "Start Monitoring" → Monitoring Screen aktif (accelerometer + mic jalan)
3. Sensor deteksi shake/fall → auto-navigate ke Incident Detected Screen
4. Countdown 10 detik muncul:
   - Jika dibatalkan → kembali ke Monitoring Screen
   - Jika tidak dibatalkan → GPS diambil → Alert terkirim ke emergency contact
5. Incident tersimpan ke History Screen (waktu, lokasi, status)

## Incident API (P6)

The repository includes a small REST backend for local end-to-end demos. Start
it with Node.js 20 or newer:

```sh
node backend/server.mjs
```

The backend listens on `http://0.0.0.0:8080`; incident data is stored in the
ignored file `backend/data/incidents.json`. The mobile app does **not** sync
history by default: emergency contacts and location history stay on-device.
If a separately secured HTTPS backend is deliberately deployed, opt in by
configuring its base URL at launch; the app appends `/incidents`:

```sh
flutter run --dart-define=API_BASE_URL=https://your-deployed-api.example/api
```

This backend is intended for local demos and testing only. It has no
authentication, so it must not be exposed publicly or used for real location
data.

The API contract used by the app is:

- `GET /incidents` returns a JSON array of incidents (an empty array means no history).
- `POST /incidents` accepts and returns one incident as a JSON object.
- `PATCH /incidents/{id}` accepts an updated incident object.
- `DELETE /incidents/{id}` removes the incident.

Incident objects use `id`, `timestamp` (ISO 8601), `latitude`, `longitude`, and
`status` (`sent`, `cancelled`, or `pending`). History displays loading, empty,
error, and success states, and allows retrying a failed load.

Run the focused API/model unit tests with:

```sh
flutter test test/incident_api_test.dart
```

Run the backend tests with:

```sh
node --test backend/server.test.mjs
```
