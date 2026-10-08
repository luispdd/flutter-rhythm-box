## MODIFIED Requirements

### Requirement: Delete Pattern
The system SHALL allow users to delete a saved pattern from the library.

#### Scenario: Delete Pattern
- **WHEN** the user confirms deletion of a pattern that is not referenced by any sequence
- **THEN** the pattern is permanently removed from the local storage and the library view.

#### Scenario: Delete Referenced Pattern
- **WHEN** the user attempts to delete a pattern that is referenced by one or more sequences
- **THEN** the system shows a warning listing the affected sequences, and if confirmed, removes the referencing entries from those sequences.
