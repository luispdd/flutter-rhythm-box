## Why

We need a dedicated metronome screen to allow the user to practice along with a simple, customizable click track, independent of the sequencer. This fulfills Milestone 2 of the initial specification and brings the previously built `MetronomeSettings` domain and core synth engine into a usable UI.

## What Changes

- Add a new `MetronomeScreen` UI to control the metronome features (beats per bar, waveform, pitch, decay, accent).
- Provide an independent Play/Stop toggle for the metronome.
- Display a visual beat indicator synchronized (approximately) with the audio engine position.
- Introduce a Riverpod `MetronomeController` (Notifier) to manage the metronome state and trigger boundary swaps on settings change.
- Implement persistence using `shared_preferences` to save/load `MetronomeSettings` and the global `Tempo` across app runs.

## Non-goals

- Tap tempo (optional feature, but not required for this milestone, we'll keep it simple).
- Advanced visual beat indicators with exact sub-millisecond precision (UI-side approximation is acceptable).
- Sequencer UI (that is Milestone 3).

## Capabilities

### New Capabilities
- `metronome`: Metronome functionality including UI controls, independent playback state, visual beat indicator, and local settings persistence.

### Modified Capabilities


## Impact

- **UI**: Adds a new screen/tab and global tempo controls.
- **State**: Introduces Riverpod providers for metronome state and global tempo.
- **Persistence**: Adds a local storage layer (`shared_preferences`) for simple JSON storage.
- **Audio Engine**: Utilizes existing `startLoop`, `swapLoopAtBoundary`, and `stop` methods. No structural changes needed.
