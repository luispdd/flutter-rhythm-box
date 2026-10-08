## 1. Persistence & State Management

- [x] 1.1 Update `SettingsStore` (and `SharedPreferencesSettingsStore`) to include `saveWorkingPattern(Pattern)` and `loadWorkingPattern()` methods. Verify by writing a unit test or simple Dart script asserting that a modified `Pattern` serializes and deserializes correctly from `SharedPreferences`.
- [x] 1.2 Create `SequencerController` (Riverpod Notifier) that holds an active `Pattern` and an `isPlaying` boolean. It should initialize by loading the working pattern from the store (or a default empty one). Verify via a unit test.
- [x] 1.3 Add pattern modification methods to `SequencerController` (e.g., `toggleStep`, `setStepCount`, `clearPattern`). Ensure each method calls `saveWorkingPattern`. Verify via unit tests.
- [x] 1.4 Integrate `SequencerController` with `AudioEngine`. Implement `togglePlay` (calls `startLoop` or `stop`). Modify the pattern update methods so that if `isPlaying` is true, they automatically call `swapLoopAtBoundary` with the newly rendered buffer. Verify via unit test using a mocked `AudioEngine`.

## 2. Sequencer UI Components

- [ ] 2.1 Build the `StepGrid` widget. It should display 8 tracks (rows) with interactive cells. The number of columns should dynamically match the active `stepCount`. Verify visually with `flutter test` widget tests.
- [ ] 2.2 Build the `SequencerControls` widget containing the Play/Stop button, a Step Count selector (4-16), and a Clear Pattern button. Verify visually with `flutter test` widget tests.
- [ ] 2.3 Implement the visual `StepPlayhead` indicator. It should listen to the `AudioEngine`'s position stream and highlight the active column in the step grid. Verify visually on the Linux desktop build.

## 3. Final Integration

- [ ] 3.1 Wire the `SequencerScreen` to the `SequencerController`. Ensure tapping grid cells toggles the state, and playback controls function correctly.
- [ ] 3.2 Update `lib/main.dart` (or the root UI widget) to provide navigation (e.g., a `BottomNavigationBar` or `TabBar`) allowing the user to switch between the existing `MetronomeScreen` and the new `SequencerScreen`.
- [ ] 3.3 Perform manual verification on Linux and Android: verify you can compose a beat, change step counts, edit the beat while it is playing without audio glitches, and that the composed beat survives an app restart.
