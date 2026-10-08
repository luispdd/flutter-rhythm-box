## Why

Now that the Sequencer UI and working pattern persistence are complete (Milestone 3), users need the ability to save their composed drum patterns, load previous patterns, and manage a library of their beats. This fulfills Milestone 4 of the initial specification.

## What Changes

- Add a "Save Pattern" flow to the Sequencer screen, prompting the user for a pattern name.
- Create a "Patterns Library" view/dialog that lists all saved patterns.
- Implement actions to Load, Rename, and Delete saved patterns from the library view.
- Introduce a Riverpod `PatternLibraryNotifier` to manage the collection of saved patterns.
- Extend `SettingsStore` (using `shared_preferences`) to persist the list of saved patterns as JSON strings.

## Non-goals

- Cloud sync or exporting patterns as audio files.
- Advanced folder structures or tagging for patterns; a simple flat list is sufficient for v1.

## Capabilities

### New Capabilities
- `pattern-library`: Management of multiple saved sequencer patterns (save, load, rename, delete) including persistent local storage and UI flows.

### Modified Capabilities


## Impact

- **UI**: Adds dialogs for saving, renaming, and deleting, plus a new library screen or full-screen dialog to list patterns.
- **State**: Introduces `PatternLibraryNotifier` and integrates its "Load" action to update both `SequencerController` and `TempoNotifier`.
- **Persistence**: Modifies `SettingsStore` to handle a collection of patterns (e.g., storing a JSON list in `shared_preferences`).
