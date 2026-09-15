# Architecture — SOS Companion

## Stack
- Frontend: Flutter (Dart)
- Local DB: Hive
- Sensors: accelerometer (sensors_plus), GPS (geolocator), mic (record)
- Remote (optional sync): PostgreSQL via Neon

## Folder Structure
sos_companion/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── monitoring_screen.dart
│   │   ├── incident_screen.dart
│   │   └── history_screen.dart
│   ├── services/
│   │   ├── accelerometer_service.dart
│   │   ├── location_service.dart
│   │   └── mic_service.dart
│   ├── models/
│   │   └── incident.dart
│   ├── widgets/
│   └── utils/
├── assets/
├── docs/
│   └── scope.md
├── test/
├── .gitignore
├── pubspec.yaml
└── README.md

## Data Flow
Sensor triggers (accelerometer/mic) → Service detects event → GPS captured
→ Save to Hive (local, always) → Sync to Neon PostgreSQL (if online, optional)

## Key Decisions
- Hive dipilih karena data simpel (incident log), tidak perlu relasi tabel kompleks
- Local-first: Hive selalu jalan meski offline, karena situasi darurat sering tanpa sinyal
- Neon PostgreSQL dipakai sebagai backup/sync layer opsional saat online
- Semua sensor pakai API bawaan HP (tidak ada hardware eksternal) untuk cost-efficiency

## Stack
- Frontend: Flutter (Dart)
- Local DB: Hive
- Sensors: accelerometer (sensors_plus), GPS (geolocator), mic (record)
- Remote (optional sync): PostgreSQL via Neon

## Folder Structure
lib/
  screens/    -> UI pages
  services/   -> sensor logic (accelerometer, location, mic)
  models/     -> data model (Incident)
  widgets/    -> reusable UI components
  utils/

## Data Flow
Sensor triggers -> Service detects event -> Save to Hive (local)
                                          -> Sync to Neon (if online)

## Key Decisions
- Hive is chosen because the data is simple (no table relation needed)
- Local-first: Hive always work even offline
- Neon used for backup/optional API layer 
