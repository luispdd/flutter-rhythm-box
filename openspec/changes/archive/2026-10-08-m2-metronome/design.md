## Context

With Milestone 1 completed, the core domain (`MetronomeSettings`), synth renderer, and `AudioEngine` (via `flutter_soloud`) are fully functional. The metronome can already be synthesized and played via the engine. This change bridges the gap by building the user interface, managing the state using Riverpod, and persisting settings to local storage. See `proposal.md` for the motivation behind this milestone.

## Goals / Non-Goals

**Goals:**
- Provide a clean, reactive UI for the metronome.
- Implement Riverpod state management for metronome state and playback control.
- Implement a simple JSON-based local persistence layer using `shared_preferences`.

**Non-Goals:**
- Precise sub-millisecond visual sync (a UI-side approximation driven by the audio engine's position stream is sufficient).
- Tap tempo feature.

## Decisions

- **State Management**: Riverpod will be used. We will introduce a `MetronomeController` (Notifier) that manages the `MetronomeSettings` and playback status (`isPlaying`). A separate `TempoController` will manage the global tempo.
- **Persistence**: We will use the `shared_preferences` package to store the `MetronomeSettings` and `Tempo` serialized as JSON strings. Why? Because the data is small and simple, and this avoids adding heavy database dependencies like SQLite or Hive.
- **Visual Beat Sync**: The `AudioEngine` will provide a stream of its current playback position. A Riverpod provider or a dedicated widget will listen to this stream, compute the current beat index based on the loop duration and tempo, and update the UI accordingly.

## Risks / Trade-offs

- **[Risk] State Sync during Boundary Swaps** → If the user rapidly changes settings while playing, multiple swaps might be scheduled.
  - **Mitigation**: Rely on the "latest-swap-wins" strategy already implemented in the `AudioEngine` to handle rapid successive changes.
- **[Risk] Visual Indicator Drift** → The UI might slightly lag behind the audio due to Flutter's frame rate or engine polling latency.
  - **Mitigation**: Clearly document that the visual indicator is approximate and does not affect the actual audio timing, adhering to the project's core principle.
