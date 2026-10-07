## 1. Domain models

- [x] 1.1 Add `Tempo` (whole BPM, clamp 30-300, default 120, increment/decrement at bounds) and verify with unit tests for default, clamping and bounds
- [x] 1.2 Add `Voice` and `Waveform` with JSON, plus the `defaultVoices` ladder (8 voices, values from the spec, gains from design D8) in one file; verify with tests for round trip, unknown waveform rejection, ladder size and track 0/7 values
- [x] 1.3 Add `Pattern` (id, name, tempoBpm, stepCount 4-16, 8x16 steps, immutable toggle/clear/setStepCount, JSON); verify with tests for new-pattern defaults, shrink-then-grow preserving steps, toggle not mutating the original, clear keeping metadata, JSON round trip and malformed JSON errors
- [ ] 1.4 Add `MetronomeSettings` (ranges, defaults, accent pitch = 1.5 x pitch, JSON with default fallback, noise rejected); verify with tests for defaults, clamping, round trip and partial JSON

## 2. Synth renderer

- [ ] 2.1 Extract the rounding helpers (`samplesPerStep`, onset index, loop length, metronome bar length) from `ClickSynthesizer` into a shared timing utility; verify with tests at 120 BPM (88200 samples for 16 steps) and 130 BPM (fractional step length, non-accumulating)
- [ ] 2.2 Implement the voice renderer (waveforms, exponential sweep, 1.5 ms attack, exponential decay, seeded noise, one-pole filters); verify with tests for first sample 0, peak within 2 ms, decay below 1 percent at 5x the decay length, noise high-pass spectrum, and byte-identical output across two renders
- [ ] 2.3 Implement the pattern renderer (per-track gain, `tanh` limiter, only the first `stepCount` steps); verify with tests for exact buffer length, onset indices, hidden steps not played, all-tracks-active within 16-bit range without clipped runs, and determinism
- [ ] 2.4 Implement the metronome renderer (configured waveform, pitch, decay, accent on beat 1); verify with tests for bar length for 2 to 9 beats, accent dominant frequency near 1.5 x pitch and no accent when off

## 3. Audio buffer and engine

- [ ] 3.1 Slim `AudioBuffer` (drop `bpm` and `stepCount`) and update its users; verify `flutter analyze` is clean and `flutter test` passes
- [ ] 3.2 Add a fake `AudioEngine` for tests that records starts, swaps and stops; verify it with a test that exercises start, swap, latest-wins and stop
- [ ] 3.3 Rework `SoLoudAudioEngine` swap handling per design D9 (separate audible and pending state, cancel pending on a new swap, dispose the audible source only after its boundary); verify on Linux that three rapid swaps play only the last one and that the audible loop is not cut early
- [ ] 3.4 Re-run the Linux 5-minute and swap benchmarks (`python3 tools/run_full_benchmarks_linux.py`) after the engine change; verify the numbers still meet the loop-timing criteria and compare them with the archived M0 results

## 4. Shared tempo and playback layer

- [ ] 4.1 Add the tempo `Notifier` provider; verify with a provider test that changing it updates listeners and that it clamps
- [ ] 4.2 Replace `PlaybackNotifier` and `PatternPreset`/`PlaybackState` with metronome and sequencer playback controllers that read tempo and settings or pattern, render, and call the engine (start, swap at boundary, stop); verify with tests using the fake engine and `audioEngineProvider.overrideWithValue`, including a tempo change causing a swap and not a restart
- [ ] 4.3 Adapt the spike screen to the new layer and remove the old synthesizer; verify the app launches on Linux, both loops play, tempo and pattern swaps work while playing, and `flutter test` and `flutter analyze` pass
- [ ] 4.4 Confirm by code search that no `Timer`, `Future.delayed` or periodic scheduler triggers any sound (the 50 ms position timer is display-only and documented as such)

## 5. Wrap-up

- [ ] 5.1 Run `flutter analyze`, `flutter test` and `openspec validate --all`; record the results and the benchmark comparison in `design.md` and report to the user
