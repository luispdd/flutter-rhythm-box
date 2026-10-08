## 1. Domain Models and Persistence

- [x] 1.1 Create `SequenceEntry` and `Sequence` domain models (pure Dart). Include JSON serialization methods. Verify with a unit test demonstrating round-trip serialization.
- [x] 1.2 Update `SettingsStore` (and `SharedPreferencesSettingsStore`) to add `saveSequenceLibrary(List<Sequence>)` and `loadSequenceLibrary()` methods. Verify with a unit test.

## 2. Rendering (Audio Synthesis)

- [x] 2.1 Extend `SynthRenderer` with a `renderSequence` method. It should take a `Sequence` and a map/list of its referenced `Pattern`s, render each pattern's loop at its native tempo, repeat it, and concatenate them into a single `Float32List`.
- [x] 2.2 Verify sequence rendering with a unit test: create a sequence `[Pattern A x 2, Pattern B x 1]` (where A and B have different tempos) and assert the final buffer length exactly matches the sum of the expected sample lengths.
- [x] 2.3 Implement an isolate/compute wrapper for `renderSequence` to ensure large buffers do not block the UI thread. Verify via a simple manual test or unit test.

## 3. State Management

- [x] 3.1 Create `SequenceLibraryNotifier` (Riverpod) to load the library from the store and handle `save`, `rename`, and `delete` operations. Verify via unit tests.
- [x] 3.2 Update `PatternLibraryNotifier`'s delete method to implement cascading updates: when a pattern is deleted, it must update `SequenceLibraryNotifier` to remove any entries referencing that pattern. Verify via a unit test.
- [x] 3.3 Create `SequenceController` (Riverpod) to manage active sequence playback (Play/Stop, loop mode). It should trigger the `AudioEngine` using the isolate-rendered buffer, mutually exclusively stopping the `MetronomeController` and `SequencerController`. Verify via unit tests.

## 4. User Interface

- [x] 4.1 Create `SequencesScreen` and add it as a third main tab in the app navigation. Verify visually that the tab routes correctly.
- [x] 4.2 Build the Sequence Library list view (similar to the pattern library) allowing users to Load, Rename, and Delete sequences. Verify actions visually and in state.
- [x] 4.3 Build the `SequenceEditor` widget. Provide an "Add Entry" button (opening a pattern picker dialog), a reorderable list of entries, and a repeat count control (+/- buttons) for each entry. Include a Loop/Play-Once toggle switch. Verify visually via widget tests or manual testing.
- [x] 4.4 Implement approximate visual playhead tracking in the sequence editor by mapping the `AudioEngine` position stream to the cumulative length of the entries. Verify visually during playback.

## 5. Timing Verification (Acceptance)

- [x] 5.1 Run the `tools/analyze_timing.py` script against a 5-minute recording of a looping sequence containing at least two patterns with different tempos on a real Android device (or Linux). Verify that max deviation remains < 3 ms and cumulative drift < 5 ms across the entry transitions. Record the output in the PR/commit.
