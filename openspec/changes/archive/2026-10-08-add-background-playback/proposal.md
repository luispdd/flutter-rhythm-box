## Why

Users need the metronome, pattern sequencer, and sequences to continue playing steadily when the Android device's screen turns off or the app goes to the background, so they can use it while playing an instrument. This implements Milestone 7 of the Phase 2 specification.

## What Changes

- Add a custom native Kotlin foreground service with a `media-playback` service type to keep the process alive in the background on Android.
- Display a persistent `MediaStyle` notification while playing, featuring a "Stop" control.
- Link the notification's Stop button back to the Flutter app via a `MethodChannel` to cleanly halt audio playback.
- Exclude audio focus and headphone disconnection behaviors as explicitly requested by the user.

## Non-goals

- Implementing audio focus request or headphone unplug detection (explicitly skipped by user).
- Implementing background playback on Linux (not applicable).

## Capabilities

### New Capabilities
- `background-playback`: Defines the behavior and lifecycle of the background audio service and its persistent notification.

## Impact

- **Android Native**: Adds a small custom Kotlin service (`ForegroundService`) and updates `AndroidManifest.xml` with required permissions (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`).
- **Communication**: Establishes a `MethodChannel` between the Dart audio controllers and the Kotlin service.
