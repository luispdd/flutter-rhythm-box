## Context

With Milestones 1-4 complete, users can create, save, and play individual patterns. Milestone 5 introduces `Sequences` (lists of pattern references) to build songs. Based on discussions with the user, we will render sequences into a single large audio buffer to guarantee sample-accurate tempo transitions, and silently ignore missing pattern references upon load to keep things simple.

## Goals / Non-Goals

**Goals:**
- Implement a `Sequence` domain model holding references (`patternId`, `repeats`).
- Build a Sequence editor UI to add, reorder, and configure repeats.
- Extend `SynthRenderer` to concatenate multiple patterns (at their respective tempos) into a single continuous PCM buffer.
- Manage sequence state via a `SequenceLibraryNotifier`.
- Cascading deletes: if a Pattern is deleted, remove its references from all saved Sequences.

**Non-Goals:**
- Nested sequences or overlapping patterns.
- Tempo overrides per sequence entry.
- Exporting the sequence as an audio file.

## Decisions

- **Buffer Approach**: Instead of enqueuing small buffers in the audio engine, the `SynthRenderer` will render the *entire* sequence (capped at 10 minutes) into one large `Float32List` buffer. Since `flutter_soloud` expects a single PCM buffer, this guarantees perfect sample accuracy across transitions. Because rendering this buffer might block the UI thread for a few dozen milliseconds, we will run the concatenation logic in an `Isolate` (via `compute()`).
- **Missing References**: If a sequence JSON contains a `patternId` that no longer exists in the library, the system will silently ignore it during load and only present the valid entries.
- **State Management**: A new `SequenceLibraryNotifier` will hold `List<Sequence>`. A `SequenceController` (similar to `SequencerController`) will hold the active sequence being edited/played.
- **Cascading Delete**: When `PatternLibraryNotifier` deletes a pattern, it will read `SequenceLibraryNotifier` and invoke an update to strip that pattern ID from all sequences.

## Risks / Trade-offs

- **[Risk] Memory Usage for Large Sequences** → A 10-minute stereo Float32 buffer at 44.1kHz takes roughly 10MB of RAM.
  - **Mitigation**: 10MB is trivial for modern smartphones. We will enforce the 10-minute cap (or a similar max sample count limit) during rendering to prevent OOM errors if a user inputs 99 repeats of a very slow pattern.
- **[Risk] Long Render Times** → Synthesizing 10 minutes of audio might take ~100-300ms in Dart.
  - **Mitigation**: Offload `SynthRenderer.renderSequence` to an `Isolate` using Flutter's `compute`. The UI can show a brief loading spinner.
