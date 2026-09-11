# Architecture — SOS Companion

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
- Hive dipilih karena data simpel (tidak perlu relasi tabel)
- Local-first: Hive selalu jalan meski offline
- Neon dipakai sebagai backup/API layer opsional
