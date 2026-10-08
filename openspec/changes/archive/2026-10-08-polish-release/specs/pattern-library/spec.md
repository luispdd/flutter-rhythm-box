## MODIFIED Requirements

### Requirement: List Saved Patterns
The system SHALL display all saved patterns in a library view, providing guidance when empty.

#### Scenario: View Library
- **WHEN** the user opens the pattern library and there are saved patterns
- **THEN** the system displays a list of all saved patterns, showing their names and tempos.

#### Scenario: View Empty Library
- **WHEN** the user opens the pattern library and there are no saved patterns
- **THEN** the system displays a friendly empty state hint indicating that no patterns exist yet.

## ADDED Requirements

### Requirement: Clear Pattern Confirmation
The system SHALL require confirmation before clearing a pattern in the sequencer.

#### Scenario: Clear Working Pattern
- **WHEN** the user attempts to clear the current working pattern in the sequencer
- **THEN** the system displays a confirmation dialog to prevent accidental data loss.
