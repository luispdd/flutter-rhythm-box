## Context

In Milestone 8, the sound kit data model (`Kit`, `KitRepository`, `InMemoryKitRepository`, `AssetKitRepository`) and new synthesis parameters (pulse duty cycle, LFSR noise, stepped pitch, bit crushing, downsampling) were implemented in pure Dart. Currently, only the default `classic-synth.json` asset exists, and neither `Pattern` nor `Sequence` models store a kit reference. The UI does not provide kit selection, and the track rows in `StepGrid` display generic `"Trk 1"` through `"Trk 8"` labels.

## Goals / Non-Goals

**Goals:**
- Bundle the `retro-8bit` kit in `assets/kits/retro-8bit.json` with 8 tuned chiptune voice configurations.
- Extend `AssetKitRepository` to load both `classic-synth.json` and `retro-8bit.json`.
- Add `kitId` to `Pattern` and `Sequence` with full backward-compatible JSON serialization.
- Provide a kit selector dropdown in the top AppBar of `SequencerScreen` (left of the Pattern Library icon) and `SequencesScreen` (left of the New Sequence icon).
- Display kit-specific voice labels on the sequencer track rows.
- Support live gapless loop swapping at loop boundaries when changing kits during sequencer playback.
- Render sequences using the sequence's configured `kitId`, overriding individual pattern kit IDs.
- Restore the last selected kit automatically upon application launch via the working pattern.

**Non-Goals:**
- Voice preview/audition when tapping track labels (skipped per explicit decision).
- In-app kit editor or custom user kit authoring.
- Per-pattern kit changes inside a single sequence.
- Metronome kits (metronome remains click-settings driven).
- Audio sample loading or external file imports.

## Decisions

### D1: Retro 8-bit Kit Voice Configuration
- **Decision**: Define `assets/kits/retro-8bit.json` matching the 8 tracks in SPEC-3 §9.1:
  - Track 0 (lowest): Kick (triangle, 150 → 45 Hz, decay 140 ms, gain 0.9, bitDepth 4)
  - Track 1: Low tom (pulse, duty 0.25, 180 → 70 Hz, decay 160 ms, gain 0.5)
  - Track 2: Laser (pulse, duty 0.125, 900 → 120 Hz, fast sweep, decay 120 ms, gain 0.4)
  - Track 3: Snare (lfsrNoise long, clock 16000 Hz, highpass 800 Hz, decay 120 ms, gain 0.6)
  - Track 4: Coin (pulse, duty 0.5, base 988 Hz, pitchSteps [0, 5] 60 ms each, decay 280 ms, gain 0.35)
  - Track 5: Power-up (pulse, duty 0.25, base 523 Hz, pitchSteps [0, 4, 7, 12] 45 ms each, decay 220 ms, gain 0.3)
  - Track 6: Closed hat (lfsrNoise short, clock 32000 Hz, highpass 3000 Hz, decay 35 ms, gain 0.4)
  - Track 7 (highest): Open hat (lfsrNoise short, clock 32000 Hz, highpass 5000 Hz, bitDepth 6, decay 160 ms, gain 0.35)
- **Rationale**: Direct adherence to chiptune voice parameters established in the specification.

### D2: Repository Multi-Kit Discovery and Fallback
- **Decision**: Update `AssetKitRepository` to include `assets/kits/retro-8bit.json` in default asset paths. `getKit(id)` falls back silently to `defaultKit` (`classic-synth`) if the requested ID is absent or fails to load.
- **Alternatives considered**: Showing a warning SnackBar on unknown kit fallback. Decided against notifications per explicit user direction to keep playback and loading silent and frictionless.

### D3: Data Model Extension and Backward Compatibility
- **Decision**:
  - `Pattern` gains `final String kitId` defaulting to `'classic-synth'`. `Pattern.fromJson` checks for `json['kitId'] as String? ?? 'classic-synth'`.
  - `Sequence` gains `final String kitId` defaulting to `'classic-synth'`. `Sequence.fromJson` checks for `json['kitId'] as String? ?? 'classic-synth'`.
- **Rationale**: Preserves 100% round-trip compatibility for older stored pattern and sequence files without modifying disk files unnecessarily.

### D4: Top AppBar Kit Selector UI
- **Decision**:
  - In `SequencerScreen`: Add a `PopupMenuButton<String>` or `DropdownButton<String>` widget in the `AppBar.actions` list immediately preceding the library button.
  - In `SequencesScreen`: Add the same kit selector widget in `AppBar.actions` immediately preceding the new sequence button.
  - Selecting a kit updates the controller state and triggers immediate boundary re-render if playing.
- **Rationale**: Consistent top-bar placement across screens keeps the bottom controls uncluttered and immediately visible.

### D5: Track Row Labels in StepGrid
- **Decision**: Pass `List<String> trackLabels` to `StepGrid` derived from the selected kit's voice labels. Display `trackLabels[trackIndex]` in place of generic `"Trk ${trackIndex + 1}"`.
- **Rationale**: Provides clear visual indication of voice instruments for the active kit.

### D6: Sequencer and Sequence Audio Integration
- **Decision**:
  - `SequencerController`: In `start()` and `_restartPlayback()`, resolve the active `Kit` from `KitRepository` using `state.pattern.kitId` and pass it to `PatternRenderer.renderBuffer(pattern, kit: kit, bpm: bpm)`.
  - When changing kit during sequencer playback, call `_restartPlayback(pattern: updatedPattern)` which re-renders the buffer with the new kit and invokes `_engine.swapLoopAtBoundary(buffer)`.
  - `SequenceController`: In `start()`, resolve the sequence's `Kit` using `state.sequence.kitId` and pass it to `PatternRenderer.renderSequenceBufferCompute(sequence: state.sequence, patterns: patternMap, kit: kit)`.
- **Rationale**: Uses existing audio seam and boundary-swapping mechanisms without altering core audio timing.

## Risks / Trade-offs

- **[Risk] Slower buffer rendering with complex chiptune parameters (pitchSteps, downsample, bitDepth)** → *Mitigation*: Audio buffers for single patterns are typically short (< 2 seconds); sequence rendering is offloaded to background isolates via `compute`.
- **[Risk] Corrupted or missing kit asset on disk** → *Mitigation*: `AssetKitRepository` catches loading errors and provides `defaultKit` (`classic-synth`) fallback.
