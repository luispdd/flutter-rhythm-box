## Context

The app currently allows composing a single "working pattern" on the Sequencer screen, which persists across restarts. To fulfill Milestone 4, users need the ability to maintain a collection of different saved patterns.

## Goals / Non-Goals

**Goals:**
- Provide a simple UI to browse and manage a collection of saved patterns.
- Implement Riverpod state management (`PatternLibraryNotifier`) to handle the collection.
- Persist the collection of patterns locally via `shared_preferences`.

**Non-Goals:**
- Audio export of patterns.
- Folders, tagging, or complex library organization.
- Cloud synchronization.

## Decisions

- **State Management**: A new `PatternLibraryNotifier` (Riverpod) will hold `List<Pattern>`. 
  - Loading a pattern from the library will require updating both the `SequencerController` (working pattern) and the `TempoNotifier` (global tempo). This can be achieved by reading those providers inside the library controller or from the UI event handler.
- **Persistence**: We will continue using `SettingsStore` (backed by `shared_preferences`). We will store the library as a serialized JSON string containing a list of patterns under a specific key (e.g., `saved_patterns`).
- **UI Flow**: We will add a "Save" icon/button to the `SequencerControls` widget that triggers a simple text input dialog. The library itself will be a new full-screen route or a large dialog showing a `ListView` of patterns, with trailing icon buttons for Load, Edit (Rename), and Delete.

## Risks / Trade-offs

- **[Risk] State Synchronization across Providers** → Loading a pattern updates three distinct pieces of state (Working Pattern, Global Tempo, and potentially triggering audio swaps if playing).
  - **Mitigation**: Handle the "Load" action deliberately. If the sequencer is playing, the `SequencerController`'s update method should automatically handle the `swapLoopAtBoundary` logic (which was implemented in M3). The tempo update will also trigger a swap if the metronome is playing.
- **[Risk] Large JSON Serialization Overhead** → Storing many patterns in a single `shared_preferences` key might become slow.
  - **Mitigation**: The `Pattern` model is extremely lightweight (8x16 booleans, name, id, tempo). Even 100 patterns will serialize very quickly. If it ever becomes a bottleneck, migration to `sqflite` or `hive` can happen post-v1.
