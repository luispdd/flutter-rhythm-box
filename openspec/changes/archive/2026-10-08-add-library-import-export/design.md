## Context

See `proposal.md` for motivation. Rhythm Box currently stores patterns and sequences as JSON strings in `SharedPreferences` via `SharedPreferencesSettingsStore` (`pattern_library` and `sequence_library` keys). The app runs on Linux (development/desktop) and Android (mobile practice). There are no existing file dialog or export/import utilities in the project.

## Goals / Non-Goals

**Goals:**
- Provide a clean export mechanism that serializes all saved patterns and sequences into a single envelope JSON file.
- Provide a validated, confirmed import mechanism that completely replaces stored patterns and sequences.
- Keep third-party dependencies minimal (`file_picker` only).
- Keep UI simple and accessible directly from the Metronome screen.
- Ensure audio playback is stopped before replacement and subsequent views start with clean state.

**Non-Goals:**
- Multi-file staging directories or complex transactional rollbacks.
- Android share sheet integration (`share_plus` excluded to minimize dependencies).
- Selective item export/import or library merging.

## Decisions

### Decision 1: Use `file_picker` as the single file dialog dependency
- **Choice:** Add `file_picker: ^8.1.7` (or latest compatible 8.x) to `pubspec.yaml`.
- **Rationale:** `file_picker` supports Linux (via Zenity and xdg-desktop-portal) and Android (via Storage Access Framework `ACTION_CREATE_DOCUMENT` and `ACTION_OPEN_DOCUMENT`). It handles both file picking for import and file saving for export without custom platform channel code.
- **Alternatives considered:**
  - Hand-rolled platform channels: High maintenance, requires native Kotlin and Linux GTK/C++ integration.
  - Adding `share_plus`: Excluded per user decision to keep the project simple for a solo POC.

### Decision 2: Direct replacement in `SharedPreferences` without staging files
- **Choice:** Add `replaceAll(List<Pattern> patterns, List<Sequence> sequences)` directly to `SettingsStore` and `SharedPreferencesSettingsStore`.
- **Rationale:** The entire library is stored in `SharedPreferences`. Serializing and writing both keys (`pattern_library` and `sequence_library`) in memory and persisting them directly is fast (<10 ms for typical libraries) and straightforward.
- **Alternatives considered:**
  - File-system staging directory swap: Over-engineered given that data is kept in `SharedPreferences`, which does not use file directory structures.
  - Staging keys in SharedPreferences: Unnecessary complexity for a personal POC app.

### Decision 3: UI integration in Metronome Screen AppBar
- **Choice:** Add Export and Import icon buttons (or an overflow popup menu) in the top-right `AppBar` of `MetronomeScreen`.
- **Rationale:** The Metronome screen serves as the initial home tab of the application, providing an accessible and non-intrusive central point to manage the entire library without cluttering the individual Sequencer and Sequence screens.
- **Alternatives considered:**
  - Overflow menu on both `PatternLibraryScreen` and `SequenceLibraryScreen`: Requires navigating into specific sub-screens to manage data that affects both sections.

### Decision 4: Post-import state reset for Sequencer and Sequences
- **Choice:** When an import completes, both `SequencerController` and `SequenceController` are reset to their initial/empty states (`Pattern.empty()`, `Sequence.empty()`).
- **Rationale:** Since import happens from the Metronome screen, resetting working state guarantees that when the user switches to the Sequencer or Sequences tabs, they encounter a fresh slate and can deliberately load imported patterns or sequences from their libraries.
- **Alternatives considered:**
  - Retaining dirty working state: Could leave the active sequence referencing pattern IDs that no longer exist in the newly imported library.

### Decision 5: File Envelope Format & Validation Strategy
- **Choice:** Single UTF-8 JSON file with structure:
  ```json
  {
    "format": "rhythm-box-library",
    "formatVersion": 1,
    "exportedAt": "2026-10-08T18:00:00Z",
    "appVersion": "1.0.0",
    "patterns": [ ... ],
    "sequences": [ ... ]
  }
  ```
- **Validation Pipeline:**
  1. Size sanity check (<= 10 MB).
  2. JSON syntax decoding.
  3. Envelope validation (`format == 'rhythm-box-library'`, `formatVersion <= 1`).
  4. Array structure check (`patterns` and `sequences` are lists).
  5. Deserialization validation using existing `Pattern.fromJson` and `Sequence.fromJson`.
  6. ID uniqueness check (no duplicate pattern IDs, no duplicate sequence IDs).
  7. Referential integrity check (every sequence entry's `patternId` must exist in `patterns`).

## Risks / Trade-offs

- **[Risk] Interrupted write during `replaceAll`**: If process is killed between saving `pattern_library` and `sequence_library`, state could diverge.
  → **Mitigation**: Writes are sequential asynchronous operations in memory. On error, exceptions are caught and surfaced via `appErrorProvider`. For a personal POC, the window is microsecond-level.
- **[Risk] Headless tests and native file dialogs**: Native file picker cannot open dialogs in headless `flutter test`.
  → **Mitigation**: Abstract file picker operations behind a small `FilePickerService` interface with mock/fake implementations for unit and widget tests.
