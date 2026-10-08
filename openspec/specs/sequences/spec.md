# sequences Specification

## Purpose

Provides a way to chain patterns together sequentially to form longer compositions or songs.

## Requirements

### Requirement: Sequence Data Model
The system SHALL support sequences as an ordered list of pattern references.

#### Scenario: Entry Definition
- **WHEN** a sequence is created
- **THEN** it consists of a sequence ID, a name, a loop boolean, and an ordered list of entries (Pattern ID and repeat count 1-99).

### Requirement: Independent Playback Control
The system SHALL provide a dedicated play/stop control for sequences.

#### Scenario: Start Sequence
- **WHEN** the user starts sequence playback
- **THEN** it automatically stops the metronome or pattern sequencer if they are playing.

### Requirement: Sequence Editor
The system SHALL provide an interface to manage sequence entries.

#### Scenario: Edit Sequence
- **WHEN** the user opens the sequence editor
- **THEN** they can add new pattern entries from the library, reorder them, remove them, change their repeat counts, and toggle the sequence loop mode.

### Requirement: Sequential Playback Rendering
The system SHALL render sequence entries consecutively using their individual saved properties.

#### Scenario: Render Entries
- **WHEN** a sequence is played
- **THEN** each entry plays sequentially, applying its referenced pattern's unique tempo, step count, and step data, ignoring the global tempo.

### Requirement: Graceful Missing References
The system SHALL handle missing pattern references gracefully.

#### Scenario: Load Sequence With Missing Pattern
- **WHEN** the user loads a sequence that references a pattern which has been deleted from the library
- **THEN** the system ignores the missing entry and loads the sequence with the remaining valid entries without crashing.
