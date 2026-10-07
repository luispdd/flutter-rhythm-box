## 1. Persistence Layer

- [x] 1.1 Add `shared_preferences` package dependency and verify `flutter pub get` succeeds.
- [x] 1.2 Implement a simple `SettingsStore` interface and `SharedPreferencesSettingsStore` class to save and load `MetronomeSettings` and the global `tempo` value as JSON strings. Verify with a quick Dart script or unit test that data round-trips correctly.

## 2. State Management (Riverpod)

- [x] 2.1 Create a `TempoNotifier` to hold the global BPM, initializing from `SettingsStore` and saving on updates. Verify by testing that updates trigger the store save.
- [x] 2.2 Create a `MetronomeController` (Notifier) that holds the current `MetronomeSettings` and a boolean `isPlaying`. It must load initial settings from the store. Verify via a unit test (mocking the store).
- [x] 2.3 Integrate `MetronomeController` with the `AudioEngine`. When play is toggled, call `startLoop` or `stop`. When settings or tempo change *while playing*, call `swapLoopAtBoundary`. Verify via unit tests with a mock `AudioEngine`.

## 3. User Interface

- [ ] 3.1 Build the `MetronomeScreen` layout containing Tempo controls (slider, +/- buttons), the Play/Stop button, and Metronome Settings controls (Beats per bar dropdown, Accent toggle, Waveform dropdown, Pitch and Decay sliders). Verify with `flutter test` widget tests.
- [ ] 3.2 Wire the `MetronomeScreen` to the Riverpod controllers (`ref.watch` / `ref.read`). Verify the UI reflects the loaded state and updates the controllers on interaction.
- [ ] 3.3 Implement the visual beat indicator. Create a widget that listens to the `AudioEngine`'s position stream (or the engine's `getCurrentBeat` abstraction if added) and highlights the current beat index. Verify visually by running the app on Linux desktop.

## 4. Final Integration

- [ ] 4.1 Update `lib/main.dart` to initialize Riverpod, load the `shared_preferences` instance, and display the `MetronomeScreen`.
- [ ] 4.2 Perform a full manual verification on Linux desktop and Android emulator/device to ensure settings persist across restarts, the metronome plays continuously, and settings/tempo changes during playback swap seamlessly without audio glitches.
