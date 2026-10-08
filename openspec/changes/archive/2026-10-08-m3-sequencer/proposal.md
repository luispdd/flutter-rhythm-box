## Why

With the `Pattern` domain model and core synthesis engine in place from Milestone 1, and the shared tempo and persistence layer implemented in Milestone 2, we need a dedicated UI for users to compose and play their own drum patterns. This fulfills Milestone 3 of the initial specification.

## What Changes

- Add a new `SequencerScreen` UI to control the sequencer features (Play/Stop toggle, 8x16 interactive Step Grid, adjustable Step Count, Clear Pattern button).
- Provide an independent Play/Stop toggle for the sequencer track.
- Display a visual playhead (step indicator) synchronized (approximately) with the audio engine position.
- Introduce a Riverpod `SequencerController` (Notifier) to manage the working pattern and trigger seamless audio buffer swaps on pattern edits.
- Persist the user's active "working pattern" to local storage (`shared_preferences`) on every change, ensuring their composition is preserved across app restarts.

## Non-goals

- Managing multiple saved patterns (loading/saving/deleting lists of patterns is Milestone 4).
- User-configurable synth voices (voices use the fixed 8-voice ladder defined in M1).
- Precise sub-millisecond visual step indicator sync.

## Capabilities

### New Capabilities
- `sequencer`: Sequencer functionality including the interactive step grid UI, active pattern state management, seamless playback edits, and single working-pattern persistence.

### Modified Capabilities


## Impact

- **UI**: Adds the primary `SequencerScreen` tab with a complex interactive grid widget.
- **State**: Introduces a Riverpod provider (`sequencerProvider`) holding the active `Pattern`.
- **Persistence**: Modifies the `SettingsStore` (from M2) to additionally persist the working pattern as JSON.
- **Audio Engine**: Utilizes existing `startLoop`, `swapLoopAtBoundary`, and `stop` methods. No underlying audio engine changes required.
