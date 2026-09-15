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
- Local incident history log (time, location, status)
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
- Cloud backend / multi-user accounts
- Real speech recognition (only amplitude threshold)
- Wearable device integration

## Success Criteria
- Aplikasi berhasil mendeteksi shake/fall pattern via accelerometer
- GPS location berhasil diambil otomatis saat incident terdeteksi
- Countdown + cancel berfungsi (tidak trigger alert jika dibatalkan)
- Alert/notifikasi berhasil terkirim ke emergency contact
- Data incident tersimpan secara lokal (offline-first) via Hive
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
