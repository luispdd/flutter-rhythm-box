## Context

Building on Milestones 1 and 2, the `Pattern` domain model (with step toggling, clearing, and step count adjustment), the synth renderer, and the `AudioEngine` are already implemented. We also have a `TempoNotifier` and `SettingsStore` in place from M2. This change adds the user interface for the Sequencer and its corresponding Riverpod state management.

## Goals / Non-Goals

**Goals:**
- Provide a responsive 8x16 step grid UI.
- Implement Riverpod state management for the working pattern and sequencer playback status.
- Persist the working pattern to `shared_preferences` seamlessly.
- Sync visual step indicator with audio engine playback position.

**Non-Goals:**
- Multiple pattern management (save/load library) is reserved for Milestone 4.
- User-editable voice synthesis parameters.

## Decisions

- **State Management**: We will introduce a `SequencerController` (Notifier) that holds the active `Pattern` and the `isPlaying` state. It will read the global tempo from the existing `TempoNotifier` to pass to the synth renderer.
- **Persistence**: We will extend the `SettingsStore` (from M2) to save and load the working `Pattern` as a serialized JSON string.
- **Grid UI Component**: The 8x16 grid will be built using standard Flutter layout widgets (e.g., `GridView` or `Table`, or rows/columns). We will only render columns up to the current `stepCount`.
- **Visual Playhead**: The audio engine provides a position stream. The UI will calculate the current step index by dividing the position by the duration of a single step (calculated from tempo and step count) to highlight the active column.

## Risks / Trade-offs

- **[Risk] UI Rendering Performance** → A grid of up to 128 (8x16) interactive widgets might rebuild too often if the entire grid is wrapped in a single watcher.
  - **Mitigation**: Use targeted Riverpod `select` statements or break the grid down into individual `ConsumerWidget` cells so only the toggled cells and the active playhead column rebuild.
- **[Risk] Audio Synthesis Overhead on Edit** → Re-rendering the entire 16-step buffer on every tap while playing might be computationally expensive.
  - **Mitigation**: The spike in M0 proved that synthesizing a 16-step pattern is extremely fast in Dart and can run safely. We will rely on this, but if performance degrades on slow devices, we might consider isolating the synth renderer (though not strictly necessary based on M0 results).
