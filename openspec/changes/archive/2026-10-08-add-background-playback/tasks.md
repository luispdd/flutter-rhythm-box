## 1. Native Android Implementation

- [x] 1.1 Update `android/app/src/main/AndroidManifest.xml` to declare `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permissions, and register the new `PlaybackService`. Verify by building the Android app.
- [x] 1.2 Create `PlaybackService.kt` in the Android codebase. Implement a `MediaStyle` notification with a "Stop" button and call `startForeground`. Setup a `PendingIntent` for the Stop button that broadcasts back to the main activity. Verify by checking Kotlin compilation.
- [x] 1.3 Update `MainActivity.kt` to set up a `MethodChannel` (`com.example.rhythmbox/playback`). Handle `startService` and `stopService` calls from Dart. Handle the Stop broadcast from the service by invoking `onNotificationStop` back to Dart. Verify by checking Kotlin compilation.

## 2. Flutter Integration

- [x] 2.1 Create a `BackgroundAudioService` class in Dart to encapsulate the `MethodChannel` communication. Implement `start()`, `stop()`, and an event listener for `onNotificationStop`. Verify by writing a unit test with a mocked MethodChannel.
- [x] 2.2 Update the Riverpod controllers (`MetronomeController`, `SequencerController`, `SequenceController` if it exists) to call `BackgroundAudioService.start()` when playback starts and `stop()` when it stops. Verify via unit tests.
- [x] 2.3 Wire up the `onNotificationStop` listener in the main app lifecycle or controllers to trigger the active controller's `stop()` method when the notification button is tapped. Verify via unit tests or manual verification on a Linux build (ensuring no crashes occur when the channel is unhandled on Linux).

## 3. Verification

- [x] 3.1 Verify that the app still compiles and runs correctly on Linux, and that the `MethodChannel` calls fail gracefully (or do nothing) on unsupported platforms. (Note: Real Android device testing for background audio and 10-minute limits is deferred to manual QA per user request).
