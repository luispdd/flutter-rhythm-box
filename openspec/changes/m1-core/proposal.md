## Why

M0 proved the loop/swap mechanism and left a spike-shaped codebase: one fixed click voice, preset-based patterns, a `PlaybackNotifier` tied to the spike screen, and an `AudioBuffer` that carries spike fields. M2 (metronome) and M3 (sequencer) both need real domain models, a real synth renderer and a shared tempo. They also need an engine contract that stays correct when edits arrive faster than loop boundaries (editing steps while playing).

## What Changes

- Add pure-Dart domain models with JSON serialization: `Voice`, `Pattern` (8 tracks x 16 stored steps, `stepCount` 4-16), `MetronomeSettings`, and a whole-BPM `Tempo` (30-300, default 120, clamped).
- Add the synth renderer: waveforms (sine, triangle, square, noise), exponential frequency sweep, 1-2 ms attack, exponential decay, optional high/low-pass, per-voice gain, and a `tanh` soft limiter, plus the fixed 8-voice default ladder in one place.
- Add pattern and metronome renderers that reuse the M0 rounding rule and produce the PCM loops.
- Define and test the engine contract for swaps: the latest requested swap wins, and a swap to a loop of a different length still lands on the old loop's boundary.
- Refactor the M0 spike code: fold `ClickSynthesizer` into the new renderers, slim `AudioBuffer`, replace `PatternPreset` and `PlaybackNotifier` with a shared tempo provider and a thin playback layer. The spike screen keeps working on top of them until M2/M3.
- Unit tests per spec section 10.

## Capabilities

### New Capabilities
- `voice-synthesis`: voice parameter model, the default 8-voice ladder, and deterministic PCM rendering of voices and mixes.
- `pattern-model`: the pattern data model, step-count handling that preserves steps, and its JSON form.
- `shared-tempo`: the single global tempo value shared by metronome and sequencer.
- `metronome-settings`: the metronome settings model and its JSON form (no UI or storage yet).
- `audio-engine`: the behavior contract for starting, stopping and swapping loops, including rapid successive swaps.

### Modified Capabilities
<!-- None: loop-timing guarantees from M0 are unchanged. -->

## Non-goals

- Metronome or sequencer screens, tab navigation (M2/M3).
- `shared_preferences` or any storage, including the settings and patterns stores (M2/M4/M5).
- Tap tempo, beat indicator, pattern list (M2 to M4).
- Foreground service for screen-off playback (M6).
- Editing voices in the UI; voices stay fixed in v1.
- Re-measuring timing on a real Android device (explicitly skipped by the owner).

## Impact

- New: `lib/domain` models, `lib/synth` voice/pattern/metronome renderers, shared tempo provider, new tests.
- Changed: `lib/synth/click_synthesizer.dart` (replaced), `lib/domain/audio_buffer.dart` (slimmed), `lib/domain/playback_state.dart` and `lib/ui/playback_controller.dart` (replaced by the shared tempo and playback layer), `lib/audio/soloud_audio_engine.dart` (swap handling), `lib/ui/spike_screen.dart` (adapted).
- Dependencies: none added.
