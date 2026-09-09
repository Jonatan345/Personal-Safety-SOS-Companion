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
