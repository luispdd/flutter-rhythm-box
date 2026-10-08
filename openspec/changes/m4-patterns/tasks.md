## 1. Persistence

- [x] 1.1 Update `SettingsStore` (and `SharedPreferencesSettingsStore`) to include `savePatternLibrary(List<Pattern>)` and `loadPatternLibrary()` methods. Verify by writing a unit test that serializes and deserializes a list of multiple `Pattern` objects.

## 2. State Management

- [x] 2.1 Create `PatternLibraryNotifier` (Riverpod Notifier) that holds a `List<Pattern>` and initializes by loading from the store. Verify via a unit test.
- [x] 2.2 Add methods to `PatternLibraryNotifier` to `savePattern(Pattern)`, `deletePattern(String id)`, and `renamePattern(String id, String newName)`. Ensure these methods call the store persistence layer. Verify via unit tests.

## 3. UI Components and Integration

- [ ] 3.1 Update `SequencerControls` widget to include a "Save" button. Implement a dialog that prompts the user for a pattern name, and upon confirmation, calls `PatternLibraryNotifier.savePattern` passing the current working pattern and global tempo. Verify visually and by inspecting Riverpod state.
- [ ] 3.2 Add a "Library" navigation button to the main app bar (or Sequencer controls) to open the Pattern Library view. Verify the button routes correctly.
- [ ] 3.3 Build `PatternLibraryScreen` (or a full-screen Dialog). It should use `ref.watch(patternLibraryProvider)` to display a `ListView` of saved patterns. Verify visually that saved patterns appear.
- [ ] 3.4 Implement the "Rename" and "Delete" actions on the library list items (with a confirmation dialog for delete). Verify that these actions update the library state correctly.
- [ ] 3.5 Implement the "Load" action. Tapping "Load" on a pattern in the library should: 1. Update the `SequencerController`'s working pattern. 2. Update the `TempoNotifier`'s global tempo. 3. Close the library view. Verify manually that the sequencer reflects the loaded pattern and tempo immediately.
- [ ] 3.6 Perform a full manual verification: Create a beat, adjust the tempo, save it as "Beat A". Create another beat, save it as "Beat B". Verify you can load "Beat A" and "Beat B" back-to-back, and that renaming and deleting work correctly.
