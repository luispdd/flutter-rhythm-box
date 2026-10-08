## Why

With all core features (Metronome, Sequencer, Patterns, and Sequences) completed, the application needs final polish, robust error handling, and release builds for daily use. This implements Milestone 6 of the Phase 2 specification.

## What Changes

- Add a `schemaVersion` to all serialized models to future-proof JSON persistence.
- Implement robust `try/catch` error handling for JSON parsing, storage write failures, and audio engine initialization, displaying UI warnings instead of crashing.
- Persist the last-selected UI tab and the last-opened sequence so the app restores the exact state on startup.
- Hook into app lifecycle events to cleanly dispose of the `AudioEngine` when the app shuts down.
- Add "empty state" hints to the Pattern and Sequence library lists.
- Add a confirmation dialog for "Clear Pattern" to prevent accidental data loss.
- Set the application name to "Rhythm amigo", configure the application ID, set up Android `minSdk`/`targetSdk`, and add a simple launcher icon.
- Provide a `README.md` with build, run, and test instructions.

## Non-goals

- Implementing playback with the screen off (reserved for Milestone 7).
- Play Store deployment or production release keystore configuration (skipping keystore setup per user request).

## Capabilities

### New Capabilities
- `app-lifecycle`: Defines how the app handles startup state restoration, shutdown cleanup, and global error resilience.

### Modified Capabilities
- `pattern-library`: Modifies the UI to include an empty state and a clear pattern confirmation dialog.

## Impact

- **UI**: Adds empty states, a new confirmation dialog, and SnackBar error messages.
- **Persistence**: Modifies all JSON serialization/deserialization logic to support `schemaVersion` and graceful fallback.
- **App Lifecycle**: Implements `WidgetsBindingObserver` in `main.dart` or a top-level widget.
- **Build configuration**: Modifies Android `build.gradle` and manifest files.
