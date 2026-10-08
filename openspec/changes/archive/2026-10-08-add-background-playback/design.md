## Context

See proposal.md - Why. To allow users to play instruments while the metronome runs in their pocket, the app must survive Android's aggressive background execution limits.

## Goals / Non-Goals

**Goals:**
- Keep the Dart isolate and `flutter_soloud` audio engine alive in the background on Android.
- Present a persistent foreground notification with a Stop button.
- Bridge native Kotlin service events back to the Flutter UI/Riverpod state.

**Non-Goals:**
- Handling audio focus loss or headphone disconnection (explicitly skipped).
- Background playback support for Linux.
- Using heavy dependencies like `audio_service` or `flutter_foreground_task`.

## Decisions

- **Foreground Service Implementation**: Instead of using a bulky third-party package, we will write a tiny custom native Kotlin `Service` (`PlaybackService`). This service will call `startForeground` with the `FOREGROUND_SERVICE_MEDIA_PLAYBACK` type to satisfy Android 14+ requirements.
- **Flutter to Native Communication**: We will establish a `MethodChannel` (`com.example.rhythmbox/playback`). 
  - Flutter calls `MethodChannel.invokeMethod('startService')` when playback begins.
  - Flutter calls `MethodChannel.invokeMethod('stopService')` when playback stops via the app UI.
- **Native to Flutter Communication**: The notification's "Stop" button will trigger a `PendingIntent` to the service, which then sends a message back to Flutter via `MethodChannel.invokeMethod('onNotificationStop')`. The Flutter `MethodChannel` listener will intercept this and dispatch a stop command to the active Riverpod controller (Metronome, Sequencer, or Sequence).

## Risks / Trade-offs

- **[Risk] Isolate Suspension** → Even with a foreground service, Android might throttle the Dart isolate, preventing it from rendering new buffers in time.
  - **Mitigation**: `flutter_soloud` manages audio off the main Dart thread in C++. Since our timing model relies on long, gapless looping buffers (or entire pre-rendered sequences), Dart only needs to intervene at loop boundaries. If CPU throttling causes missed boundaries, we may need to investigate partial wake locks, but we will start without them to save battery.
