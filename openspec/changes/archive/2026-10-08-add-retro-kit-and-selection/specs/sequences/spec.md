## ADDED Requirements

### Requirement: Sequence kit fallback
If a sequence specifies an unknown or missing `kitId`, sequence playback and editing SHALL silently fall back to `classic-synth`.

#### Scenario: Fallback on unknown sequence kit
- **WHEN** a sequence configured with a missing or unregistered `kitId` is loaded or played
- **THEN** the sequence renders using `classic-synth` without throwing an error

## MODIFIED Requirements

### Requirement: Sequence Data Model
The system SHALL support sequences as an ordered list of pattern references configured with a single sound kit identifier.

#### Scenario: Entry Definition
- **WHEN** a sequence is created
- **THEN** it consists of a sequence ID, a name, a loop boolean, an optional `kitId` (defaulting to `'classic-synth'`), and an ordered list of entries (Pattern ID and repeat count 1-99).

#### Scenario: Backward compatibility with missing kitId
- **WHEN** an older sequence JSON without a `kitId` field is deserialized
- **THEN** it successfully loads with `kitId` defaulting to `'classic-synth'`

### Requirement: Sequence Editor
The system SHALL provide an interface to manage sequence entries and sound kit selection.

#### Scenario: Edit Sequence
- **WHEN** the user opens the sequence editor
- **THEN** they can select the sound kit from the top AppBar (to the left of the new sequence button), add new pattern entries from the library, reorder them, remove them, change their repeat counts, and toggle the sequence loop mode.

### Requirement: Sequential Playback Rendering
The system SHALL render sequence entries consecutively using their individual pattern step patterns and tempos, rendered entirely with the sequence's configured sound kit.

#### Scenario: Render Entries
- **WHEN** a sequence is played
- **THEN** each entry plays sequentially, applying its referenced pattern's unique tempo, step count, and step data, but using the sequence's sound kit for all rendered voices, overriding any `kitId` stored within individual patterns.
