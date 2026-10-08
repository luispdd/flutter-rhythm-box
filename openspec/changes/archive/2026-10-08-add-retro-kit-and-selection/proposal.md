## Why

With the sound kit data model and voice renderer DSP extensions completed in Milestone 8, the app currently only bundles the default `classic-synth` sound set and lacks user-facing kit selection. Introducing the built-in `retro-8bit` kit and kit selection controls allows users to compose and play both standalone patterns and chained sequences with authentic NES-style chiptune sounds alongside the classic kit.

## What Changes

- **Retro 8-bit Kit Asset**: Add built-in `assets/kits/retro-8bit.json` configured with 8 chiptune drum and effect voices (triangle kick, pulse toms, lasers, coins, power-ups, and LFSR noise percussion).
- **Kit Repository Discovery**: Update `AssetKitRepository` to load and provide both `classic-synth` and `retro-8bit` kits, falling back silently to `classic-synth` for unknown kit IDs.
- **Pattern Model Kit Association**: Extend `Pattern` with a `kitId` property (defaulting to `'classic-synth'`) with backward-compatible JSON serialization.
- **Sequence Model Kit Association**: Extend `Sequence` with a `kitId` property (defaulting to `'classic-synth'`) with backward-compatible JSON serialization.
- **Sequencer Screen Kit Selection**: Add a kit selector dropdown in the top AppBar (to the left of the "Pattern library" icon) displaying the active kit and dynamically updating track row labels with voice names from the selected kit.
- **Live Sequencer Kit Swap**: When playback is active, changing the selected kit immediately re-renders the pattern buffer and swaps it at the next loop boundary without audio interruption.
- **Sequence Editor Kit Selection**: Add a kit selector dropdown in the top AppBar of the Sequences screen (to the left of the "New sequence" icon).
- **Sequence Playback Kit Override**: Render all patterns in a sequence using the sequence's configured `kitId`, overriding any kit defined in individual patterns. Kit changes take effect at the next sequence restart.
- **Persistence**: Persist the selected kit via the working pattern in local storage, restoring it automatically on application startup.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `sound-kits`: Add requirement for bundled `retro-8bit` built-in kit asset and multi-kit repository discovery.
- `pattern-model`: Add `kitId` field to pattern data model with fallback to default kit for missing or unrecognized kits.
- `sequencer`: Add kit selector in top bar, dynamic voice labels in track rows, live loop boundary swapping on kit change, and kit persistence in working pattern.
- `sequences`: Add `kitId` property to sequence data model, sequence editor kit selector in top bar, and sequence rendering using sequence kit overriding pattern kits.

## Non-goals

- No voice audition/preview when tapping track labels (skipped per explicit decision).
- No snackbar or toast notices on fallback to `classic-synth` (silent fallback).
- No in-app kit editing or user-defined kit creation UI.
- No per-pattern kit switching inside a single sequence.
- No audio sample imports or file sharing.
- No kits for the metronome (metronome remains click-settings driven).

## Impact

- **Models**: `Pattern` and `Sequence` gain optional/defaulted `kitId` fields.
- **Persistence**: `AssetKitRepository` loads `retro-8bit.json`; existing stored patterns and sequences deserialize missing `kitId` as `'classic-synth'`.
- **UI**: Top AppBar of `SequencerScreen` and `SequencesScreen` adds a kit dropdown menu; `StepGrid` displays voice labels from the active kit.
- **Audio Rendering**: `SequencerController` passes selected kit to `PatternRenderer.renderBuffer`; `SequenceController` passes sequence kit to `PatternRenderer.renderSequenceBufferCompute`.
