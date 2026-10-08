## Why

Now that users can create and save individual drum patterns (Milestones 3 and 4), they need a way to chain these patterns together sequentially to form longer compositions or songs. This implements Milestone 5 ("sequences of sequences") of the Phase 2 specification.

## What Changes

- Add a new `Sequence` domain model representing an ordered list of pattern references (ID + repeat count).
- Create a Sequences screen/tab to manage and play saved sequences.
- Provide an editor to add, remove, and reorder sequence entries, set repeat counts (1-99), and toggle loop/play-once modes.
- Extend the `SynthRenderer` to concatenate multiple patterns into a single continuous gapless audio buffer (up to a 10-minute cap).
- Implement persistence for sequences via `SettingsStore` saving only references, not pattern data.
- Modify pattern deletion to cascade updates to sequences that reference the deleted pattern (or gracefully skip missing patterns).

## Non-goals

- Overlapping audio sections or nested sequences.
- Exporting the sequence as an audio or MIDI file.
- Individual tempo overrides per sequence entry (each entry strictly uses the referenced pattern's saved tempo).

## Capabilities

### New Capabilities
- `sequences`: Defines the behavior, data model, and UI for creating, editing, and playing sequences of patterns.

### Modified Capabilities
- `pattern-library`: Modifies pattern deletion behavior to interact with the new sequences feature.

## Impact

- **UI**: Adds a new main tab for Sequences with an editor interface.
- **Renderer**: Adds a large-scale rendering method to the synth layer, which will run off the UI thread (isolate/compute).
- **State**: Introduces a `SequenceLibraryNotifier` alongside the existing pattern library notifier.
- **Audio**: Reuses the existing `AudioEngine` but feeds it significantly larger buffers (capped at 10 minutes).
