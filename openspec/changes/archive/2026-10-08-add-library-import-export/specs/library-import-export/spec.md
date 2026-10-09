## Purpose

Provides a complete, single-file JSON export and atomic replacement import mechanism for the saved pattern and sequence library, allowing seamless transfer across devices.

## ADDED Requirements

### Requirement: Export library to JSON envelope file
The system SHALL export all saved patterns and saved sequences to a single UTF-8 JSON file containing an envelope with `format: "rhythm-box-library"` and `formatVersion: 1`. If the local library is empty (0 patterns and 0 sequences), the system SHALL NOT write a file and SHALL display an informational notification ("Nothing to export").

#### Scenario: Non-empty library export
- **WHEN** user initiates library export with 3 saved patterns and 1 saved sequence
- **THEN** system prompts user for destination via save file dialog defaulting to `rhythm-box-library-YYYY-MM-DD.json`, writes the UTF-8 JSON envelope containing all patterns and sequences, and displays a confirmation message indicating 3 patterns and 1 sequence exported

#### Scenario: Empty library export
- **WHEN** user initiates library export with 0 patterns and 0 sequences in the library
- **THEN** system does not open a file picker or write a file, and displays a message indicating there is nothing to export

### Requirement: Library import validation
The system SHALL validate any imported library file against envelope schema, domain constraints, identifier uniqueness, and sequence referential integrity before mutating storage. The file SHALL be rejected if it exceeds 10 MB, is not valid JSON, has a missing or unsupported envelope format/version (`format != 'rhythm-box-library'` or `formatVersion > 1`), contains invalid pattern or sequence objects, contains duplicate pattern or sequence IDs, or contains a sequence referencing a `patternId` not present in the file's patterns.

#### Scenario: Valid file import validation passes
- **WHEN** user selects a valid JSON library file matching format version 1 with valid patterns and referencing sequences
- **THEN** system validation passes and proceeds to the user confirmation step without modifying existing stored data

#### Scenario: Malformed JSON or invalid envelope rejected
- **WHEN** user selects a file that is not valid JSON, exceeds 10 MB, or has `format` other than `rhythm-box-library`
- **THEN** system rejects the import, displays an explanatory error message, and leaves stored data completely unchanged

#### Scenario: Referential integrity violation rejected
- **WHEN** user selects a library file where a sequence references a `patternId` that does not exist in the file's `patterns` list
- **THEN** system rejects the import, displays an error message stating the missing pattern reference, and leaves stored data completely unchanged

#### Scenario: Duplicate ID rejected
- **WHEN** user selects a library file containing two patterns or two sequences with the same `id`
- **THEN** system rejects the import, displays an error message citing duplicate identifiers, and leaves stored data completely unchanged

### Requirement: Atomic library replacement on import
Upon successful file validation and user confirmation, the system SHALL immediately stop all audio playback across all controllers, completely replace all saved patterns and sequences in storage, and reset the Sequencer and Sequences controllers to clean empty initial states. If the user cancels the confirmation dialog or an error occurs during replacement, existing stored data SHALL remain untouched.

#### Scenario: User confirms import
- **WHEN** user validates a file with 4 patterns and 2 sequences and confirms the replacement dialog
- **THEN** active playback on all controllers stops, storage is updated so only the 4 patterns and 2 sequences exist, Sequencer and Sequences controllers reset to clean empty states, and a confirmation message is displayed

#### Scenario: User cancels import
- **WHEN** user opens the import confirmation dialog and taps Cancel
- **THEN** dialog closes, audio playback continues uninterrupted, and stored library data is not modified

#### Scenario: Importing empty library file clears stored data
- **WHEN** user imports and confirms a valid library file with 0 patterns and 0 sequences
- **THEN** storage is updated to clear all patterns and sequences, leaving the library empty

### Requirement: Metronome screen UI integration
The system SHALL provide Export and Import library actions in the top-right app bar of the Metronome tab.

#### Scenario: Triggering export from Metronome screen
- **WHEN** user taps the Export action in the Metronome screen top-right app bar
- **THEN** the export workflow is initiated

#### Scenario: Triggering import from Metronome screen
- **WHEN** user taps the Import action in the Metronome screen top-right app bar
- **THEN** the system file picker opens to select a JSON library file
