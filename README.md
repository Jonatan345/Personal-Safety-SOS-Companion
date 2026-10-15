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

## Must-Have Features
- Real-time accelerometer-based fall/shake detection
- GPS location capture triggered on incident
- Countdown screen with cancel option (avoid false alarm)
- Emergency contact input & validation
- SMS/notification alert sent automatically to emergency contact
- Incident history stored and loaded through the REST backend (time, location, status)
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
- Riwayat insiden tersimpan dan dimuat melalui API backend
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

Configure the backend base URL at launch; the app appends `/incidents`:

```sh
flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api
```

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
