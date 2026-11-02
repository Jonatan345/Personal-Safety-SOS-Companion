# Project Scope — SOS Companion

## Problem Statement
Solo commuters/students lack a quick way to alert emergency contacts
when they fall, get into an accident, or feel unsafe while alone.

## Target User
Students/individuals who frequently travel or walk alone.

## App Value
Detects potential incidents (fall/shake or loud sound), captures the location
and prepares an alert to an emergency contact without manual dialing.

## In Scope
- Accelerometer-based fall/shake detection
- Microphone amplitude threshold (85 dB) as secondary trigger
- Countdown (10 s) + cancel to avoid false alarms
- GPS location capture on trigger; if it fails the incident is stored with no
  location and the user is told why
- Local incident history (Hive): create, read, update status, delete
- Local emergency contact (one contact) with validation
- Device notification and SMS composer with a Google Maps link when a location
  exists (the user confirms the final SMS send)
- Runtime permissions: microphone (required for monitoring), notifications
  (requested without blocking monitoring), location (requested at incident time)
- Optional REST sync to a demo backend (`API_BASE_URL`)

## Out of Scope
- Multiple emergency contacts
- User accounts and a production/cloud backend (the Node.js backend is a local
  demo only, with no authentication)
- Monitoring while the app is closed or the screen is locked (no foreground
  service); the monitoring screen must stay open
- Fully automatic SMS sending without user confirmation
- Real speech recognition (only amplitude threshold)
- Wearable device integration
