## Why

Users need to transfer their entire library of saved patterns and sequences between devices (e.g., from Linux to Android or vice versa) without manual reproduction. A single-file export and import mechanism solves this by backing up and restoring the full library in a portable format.

## What Changes

- Add library export functionality that serializes all saved patterns and sequences into a single UTF-8 JSON envelope file (`rhythm-box-library`).
- Add library import functionality using `file_picker` that validates the file, requests explicit confirmation, stops all playback, and atomically replaces the local library.
- Add `replaceAll(patterns, sequences)` to `SettingsStore` / `SharedPreferencesSettingsStore` to overwrite library contents directly in storage.
- Add Export and Import actions to the top-right app bar of the Metronome tab.
- Reset the sequencer and sequence controllers to clean default states on import so entering other tabs presents an empty slate.
- Document library transfer usage in `README.md`.

## Non-goals

- Merging libraries or resolving item-by-item conflicts.
- Partial export/import of individual patterns or sequences.
- Exporting global tempo, metronome settings, or audio/MIDI data.
- Cloud sync, background auto-backups, encryption, or compression.
- Multi-step rollback or undo of completed imports.

## Capabilities

### New Capabilities
- `library-import-export`: Export and import of all saved patterns and sequences via a validated JSON envelope file with complete library replacement.

### Modified Capabilities
<!-- None: existing pattern-library and sequences specs remain valid for normal CRUD operations. -->

## Impact

- **Dependencies**: Adds `file_picker` package to `pubspec.yaml` for system file open and save dialogs.
- **Storage**: Adds `replaceAll(patterns, sequences)` method to `SettingsStore` interface and `SharedPreferencesSettingsStore`.
- **UI**: Adds export and import actions to `MetronomeScreen` AppBar; adds import confirmation dialog.
- **Audio/Controllers**: Coordinates stopping playback across all controllers before replacement and resets working states.
