## 1. Metronome Screen Compact UI

- [x] 1.1 Relocate BPM display to `MetronomeScreen` AppBar as an inline badge/subtext and remove the redundant title text above the tempo slider, verifying visually and via widget tests.
- [x] 1.2 Replace the full-width Metronome Play/Stop button with an icon-only button positioned directly to the right of the beat indicator numbers in `BeatIndicator`.
- [x] 1.3 Update `test/ui/metronome_screen_test.dart` to match the new top bar BPM format and icon-only playback button, verifying with `flutter test test/ui/metronome_screen_test.dart`.

## 2. Sequencer Controls & Collapsible Track Labels

- [x] 2.1 Implement `trackLabelsVisibleProvider` defaulting to hidden on Android/iOS and visible on desktop.
- [x] 2.2 Reorder `SequencerControls` to `[Toggle Labels] -> [Steps Slider] -> [Clear] -> [Save] -> [Play/Stop]`, converting Clear, Save, and Play/Stop into icon buttons with tooltips.
- [x] 2.3 Update `StepGrid` and `StepPlayhead` to collapse the 76dp label width to zero when hidden, allowing step buttons and playhead columns to expand to 100% of the horizontal width.

## 3. Sequencer Top Bar & Scrollability

- [x] 3.1 Relocate BPM display to `SequencerScreen` AppBar with title overflow protection and remove the redundant title text above the tempo slider.
- [x] 3.2 Set `StepGrid` track rows to fixed heights (36.0dp) and wrap `SequencerScreen` body in a `SingleChildScrollView` to support landscape orientation without squishing or overflows.
- [x] 3.3 Update `test/ui/sequencer_screen_test.dart` to reflect the new icon button keys/tooltips and add test coverage for track label toggle and scrollable grid layout, verifying with `flutter test test/ui/sequencer_screen_test.dart`.

## 4. Verification

- [x] 4.1 Run `flutter analyze` and `flutter test` across the entire codebase to confirm zero analyzer errors and all unit and widget tests pass.
