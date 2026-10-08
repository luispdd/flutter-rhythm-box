## Why

Rhythm Box currently uses a single hard-coded ladder of 8 synthesized voices. To support varied genres and sound palettes—starting with a retro 8-bit NES-style kit—Milestone 8 introduces data-driven sound kits and extends the pure-Dart synthesizer with pulse waves, NES LFSR noise, pitch stepping, bit crushing, and sample-rate reduction.

## What Changes

- **Sound Kit Model & JSON Schema**: Define `Kit` domain model containing exactly 8 voices, with validation rules ensuring stable parameter ranges.
- **Built-in Kit Migration**: Convert the existing hard-coded 8-voice ladder into `assets/kits/classic-synth.json` (`id: classic-synth`, name "Classic synth").
- **Kit Repository Abstraction**: Introduce `KitRepository` to load, validate, and retrieve kits from bundled application assets.
- **Voice Parameter Extensions**: Add optional parameters to `Voice`:
  - `label`: Track row name (Kick, Low tom, Mid perc, High perc, Low synth, High synth, Snare, Hat).
  - `waveform`: Extend `Waveform` with `pulse` and `lfsrNoise`.
  - `dutyCycle`: Pulse wave duty ratio (0.05–0.95).
  - `lfsrClockHz` & `lfsrShort`: Clock frequency and 15-bit long vs 7-bit short sequence modes for LFSR noise.
  - `pitchSteps`: Stepped frequency sequence (`semitones`, `stepMs`) overriding continuous sweeps.
  - `bitDepth`: Bit crushing quantization (2–16 bits).
  - `downsampleHz`: Sample-and-hold rate reduction.
- **Synthesizer Renderer Updates**:
  - Implement pulse oscillator with adjustable duty cycle.
  - Emulate NES-style 15-bit LFSR clocked at `lfsrClockHz` and resampled to 44.1 kHz.
  - Implement pitch steps arpeggiation clamped to final semitone on step expiration.
  - Apply sample-rate reduction and bit crushing prior to highpass/lowpass filtering.
  - Maintain deterministic output derived from kit ID and track index.
- **Golden Regression Suite**: Capture and verify pre-refactor audio buffers/hashes ensuring existing synthesis remains bit-identical when new parameters are absent.

## Non-goals

- In-app kit selection dropdown or track label switching in the UI (Milestone 9).
- Retro 8-bit kit preset tuning and selection (Milestone 9).
- Kit assignment in sequence library / pattern persistence (Milestone 9).
- User kit creation/editing UI or reading external filesystem kits from app documents.
- Metronome kits (metronome remains isolated with its dedicated click synthesizer).

## Capabilities

### New Capabilities
- `sound-kits`: Kit data definition (8 voices), JSON schema, validation rules, asset loading, and repository interface.

### Modified Capabilities
- `voice-synthesis`: Extends voice waveforms (`pulse`, `lfsrNoise`), adds pitch stepping, bit crushing, downsampling, and updates deterministic seeding rules.

## Impact

- **Domain Models**: `Voice` gains new optional properties and `Waveform` gains two values; new `Kit` model and `PitchSteps` class.
- **Synthesizer**: `VoiceRenderer` and `PatternRenderer` accept parameterized `Kit` voices while defaulting to `classic-synth`.
- **Assets**: `pubspec.yaml` updated to bundle `assets/kits/classic-synth.json`.
- **Dependencies**: No external audio dependencies; pure Dart implementation.
