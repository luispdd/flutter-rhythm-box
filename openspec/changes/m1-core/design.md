## Context

M0 is archived: the loop/swap mechanism is one looping handle, with swaps scheduled on the SoLoud engine clock, behind the `AudioEngine` interface. See proposal.md for scope. Current code is spike-shaped: `ClickSynthesizer` (fixed click), `PatternPreset` and `PlaybackState`, `PlaybackNotifier` (tied to the spike screen), and `AudioBuffer` carrying `bpm` and `stepCount`.

## Goals / Non-Goals

**Goals:**
- Real domain models and a real renderer that M2 and M3 only need to put screens on.
- An engine contract that is correct for rapid successive swaps.
- Keep the spike screen working throughout (refactor, not rewrite).

**Non-Goals:**
- Storage, navigation or new screens.
- Changing the loop/swap mechanism chosen in M0.

## Decisions

**D1. Refactor and reuse the spike layers.** `ClickSynthesizer`'s rounding helpers (`samplesPerStep`, onset index, loop length) move into a shared timing utility used by both renderers, and the old class is removed. `AudioBuffer` keeps `wavBytes`, `pcmSamples`, `sampleRate`, `totalSamples` and `duration`; `bpm` and `stepCount` are dropped. *Alternative:* keep the old synth beside the new one. Rejected, because it would leave two sources of truth for timing math.

**D2. Domain models are immutable value classes** with `copyWith`, `==`/`hashCode`, and `toJson`/`fromJson`, hand-written with no codegen. *Alternative:* `freezed`/`json_serializable`. Rejected to keep dependencies minimal; the models are small.

**D3. Tempo is a Riverpod `Notifier<int>`** holding whole BPM clamped to 30-300. The metronome and sequencer playback layers read it. *Alternative:* a `double` BPM. Rejected: the spec's controls (numeric entry, +/- buttons, slider) are whole-number controls, and a whole BPM keeps tests simple. The renderer API still takes a `double` so fractional tempos are not blocked later.

**D4. Playback layer.** `PlaybackNotifier` is replaced by a thin layer with two independent controllers (metronome and sequencer) that read tempo, settings or pattern, render a buffer, and call the engine. Audio logic stays out of widgets. Only one source plays at a time through the single engine in M1; independence at the UI level (own Play/Stop buttons) is handled in M2/M3 and the open question of mixing both is recorded below. The spike screen is adapted to call this layer.

**D5. Voice rendering.** One pass per voice into a `Float64List`, scaled by per-voice gain; phase accumulated from the instantaneous frequency (`start * (end/start)^(t/len)`) so the sweep is smooth. Envelope: linear attack of 1.5 ms, then `exp(-t / tau)` with `tau` set so the amplitude is about 60 dB down at `decayMs`. Square and triangle are naive (not band-limited): acceptable for a drum-machine POC, noted as a trade-off. The final mix is `tanh(sum)` converted to 16-bit.

**D6. Noise is deterministic.** Each voice gets its own seeded PRNG (fixed seed per track index), so the same pattern always renders the same bytes. *Assumption (owner did not answer):* identical hits every time are fine for v1. Per-hit variation can come later.

**D7. Filters** are one-pole high-pass and low-pass written in Dart (no package). *Alternative:* biquad. One-pole is enough for hat/snare-like shaping and keeps the code short; revisit by ear in M5.

**D8. Default ladder values and gains.** Taken from the spec table. The spec gives no gain numbers for the "lower gain" square tracks; starting values are 0.8 for tracks 0-3, 0.4 for tracks 4-5, and 0.6 for noise tracks. All live in one `defaultVoices` list, tuned by ear later.

**D9. Rapid swaps: latest wins (engine fix).** Reading the current engine: a second swap before the first boundary computes its boundary from the pending buffer, and the "retire previous source" step disposes the audible source early. M1 changes the engine to track `audible` and `pending` separately, store the boundary time, and on a new swap: cancel the pending handle (`stopScheduled` or stop before it starts), dispose only the cancelled pending source, and schedule the new buffer at the same boundary, which is derived from the audible loop's length and the engine-clock anchor. The audible source is disposed only after its boundary has passed. *Alternative:* queue all swaps in order. Rejected, because intermediate edits are never meant to be heard (owner decision: latest wins).

**D10. Position stream.** The existing 50 ms `Timer.periodic` only emits a position for display and never schedules sound. It stays, and is documented as display-only. M2 will use it for the beat indicator.

**D11. Tests.** Pure-Dart tests for renderers and models (`flutter test`); playback layer tested with a fake `AudioEngine` injected through the provider override. The SoLoud swap logic (D9) cannot run headless, so it is checked on Linux with a short benchmark run using the existing tooling, in addition to the unit tests of the fake.

## Risks / Trade-offs

- [D9 rewrites code that passed the M0 measurements] → Re-run the Linux 5-minute and swap benchmarks (existing scripts) after the change and compare with the archived numbers.
- [Naive square/triangle alias at high pitches] → Acceptable for a POC; listen on Android and tune in M5.
- [Filter and envelope shaping are checked only by simple spectral tests] → Keep thresholds loose and verify by ear.
- [Refactoring `PlaybackNotifier` breaks the spike screen] → Update `playback_controller_test` and `widget_test` in the same task group and keep `flutter test` green at each step.

## Open Questions

- Should the metronome and sequencer be able to play at the same time? M1 supports one at a time through the single engine; M2/M3 decide whether a second engine instance is needed. This does not change the M1 specs or tasks.
