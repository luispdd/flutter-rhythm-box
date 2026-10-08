# Pattern Library Specification

## Purpose

Provides a library system to save, load, rename, and delete multiple sequencer patterns for later use.

## Requirements

### Requirement: Save Pattern
The system SHALL allow users to save their current working sequencer pattern with a custom name.

#### Scenario: Save New Pattern
- **WHEN** the user initiates a save from the sequencer and provides a name
- **THEN** the current working pattern (including step data, step count, and global tempo) is persisted to the local library.

### Requirement: List Saved Patterns
The system SHALL display all saved patterns in a library view, providing guidance when empty.

#### Scenario: View Library
- **WHEN** the user opens the pattern library and there are saved patterns
- **THEN** the system displays a list of all saved patterns, showing their names and tempos.

#### Scenario: View Empty Library
- **WHEN** the user opens the pattern library and there are no saved patterns
- **THEN** the system displays a friendly empty state hint indicating that no patterns exist yet.

### Requirement: Load Pattern
The system SHALL allow users to load a saved pattern into the sequencer.

#### Scenario: Load Pattern
- **WHEN** the user selects a pattern to load from the library
- **THEN** the sequencer's working pattern is replaced by the selected pattern, and the global tempo is updated to match the pattern's saved tempo.

### Requirement: Rename Pattern
The system SHALL allow users to rename an existing saved pattern.

#### Scenario: Rename Pattern
- **WHEN** the user renames a pattern in the library
- **THEN** the new name is persisted and displayed in the library view.

### Requirement: Delete Pattern
The system SHALL allow users to delete a saved pattern from the library.

#### Scenario: Delete Pattern
- **WHEN** the user confirms deletion of a pattern that is not referenced by any sequence
- **THEN** the pattern is permanently removed from the local storage and the library view.

#### Scenario: Delete Referenced Pattern
- **WHEN** the user attempts to delete a pattern that is referenced by one or more sequences
- **THEN** the system shows a warning listing the affected sequences, and if confirmed, removes the referencing entries from those sequences.

### Requirement: Clear Pattern Confirmation
The system SHALL require confirmation before clearing a pattern in the sequencer.

#### Scenario: Clear Working Pattern
- **WHEN** the user attempts to clear the current working pattern in the sequencer
- **THEN** the system displays a confirmation dialog to prevent accidental data loss.
