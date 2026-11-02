# Architecture — SOS Companion

## Stack
- Flutter / Dart, Material 3
- State management: Riverpod (`StateNotifier` and `AsyncNotifier`)
- Local storage: Hive (JSON strings in versioned boxes)
- Sensors and device: `sensors_plus` (accelerometer), `noise_meter`
  (microphone level), `geolocator` (GPS), `permission_handler`,
  `flutter_local_notifications`, `url_launcher` (SMS composer)
- Optional remote: REST backend `backend/server.mjs` (Node.js, demo only)

## Repository structure
```text
Personal-Safety-SOS-Companion/
├── android/ ios/ web/ linux/ macos/ windows/   # platform runners
├── backend/
│   ├── server.mjs               # demo REST API (no auth, local use only)
│   └── server.test.mjs
├── docs/                        # scope, P4 state management, P7/P8 evidence
├── lib/
│   ├── main.dart                # entry point, ProviderScope, warm-up of services
│   ├── models/                  # Incident, EmergencyContact
│   ├── notifiers/               # Riverpod state (incident, emergency contact)
│   ├── repositories/            # data access (Hive) behind abstractions
│   ├── routes/app_routes.dart   # named routes
│   ├── screens/                 # home, monitoring, incident, history, contact setup
│   ├── services/                # sensors, location, permissions, alerts, API, storage
│   ├── theme/app_theme.dart
│   ├── use_cases/               # emergency contact load/save
│   ├── utils/                   # app_config (ambang), formatters, error_messages, sos_message
│   └── widgets/                 # AppCard, AppInputField, PrimaryButton, StatusBadge,
│                                # ResponsiveBody/ContentWidth, LoadingView/StateMessageView
├── test/                        # widget, repository, notifier and API tests
├── pubspec.yaml
└── README.md
```

## Layers
```text
Screen (UI)  ->  Notifier (state)  ->  Use case / Repository  ->  Hive / REST
MonitoringScreen -> MonitoringService (sensors)
IncidentScreen   -> LocationService, IncidentNotifier, AlertGateway
```
Screens never touch Hive directly. Services that talk to the platform sit
behind small interfaces (`MonitoringController`, `AlertGateway`,
`EmergencyContactRepository`) so tests can replace them.

## Runtime flow
1. **Monitoring** asks for the microphone permission (the only prerequisite),
   then starts the accelerometer (>= 25 m/s²) and microphone (>= 85 dB) streams.
   Notification permission is requested without blocking. Permission and sensor
   start-up have timeouts and a retry action.
2. A trigger (or the *Simulasikan* button) opens the **Incident** screen:
   10-second countdown, cancel at any time.
3. When the countdown ends: GPS is read. On failure the incident is stored
   with `latitude/longitude = null` and the user sees the reason.
4. The incident is saved (Hive), the app opens **History**, then shows a
   notification and opens the SMS composer (with a Maps link only if a location
   exists). Every failure is reported in a SnackBar.
5. After the incident screen closes, monitoring keeps working.

## Data
- `Incident`: id, timestamp, nullable latitude/longitude, status
  (`sent` | `cancelled` | `pending`). Stored as JSON in box `incidents_v2`.
- `EmergencyContact`: id, name, phoneNumber. Box `emergency_contacts_v2`.
- Optional sync: if `--dart-define=API_BASE_URL=...` is set, create, update and
  delete are mirrored to the REST API, and History loads local data first and
  then merges data from the backend (`IncidentRepository.syncFromServer`).
  A sync failure keeps the local list and shows a banner in Indonesian.
- Constants live in one place: `SosConfig` (thresholds, countdown),
  `IncidentStatus` (status values), `LocalStorageService` (Hive box names),
  `AppRoutes` (route names).

## Key decisions and limitations
- Local-first: emergencies often happen without signal.
- The SMS composer needs the user to press send; the app cannot send SMS silently.
- Monitoring works only while the app is in the foreground.
- Release builds block cleartext HTTP; debug builds allow it for the local demo backend.
