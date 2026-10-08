## Purpose

Defines how the application handles startup state restoration, shutdown resource cleanup, and global error resilience to ensure a robust user experience.

## ADDED Requirements

### Requirement: State Restoration
The system SHALL restore the last active state upon startup.

#### Scenario: App Startup
- **WHEN** the application is launched
- **THEN** it restores the last-used global tempo, metronome settings, the sequencer's working pattern, and the last-selected UI tab.

### Requirement: Graceful Error Handling
The system SHALL handle errors gracefully without crashing or losing data.

#### Scenario: Corrupted JSON File
- **WHEN** the system attempts to load a corrupted or unreadable JSON file (pattern, sequence, or settings)
- **THEN** the system does not crash, skips the corrupted data while preserving the rest, shows a short UI warning, and never automatically deletes the file.

#### Scenario: Storage Write Failure
- **WHEN** saving data to local storage fails (e.g., due to permissions or disk full)
- **THEN** the system maintains the state in memory and displays a UI error message.

#### Scenario: Audio Engine Initialization Failure
- **WHEN** the audio engine fails to initialize or the audio device is lost
- **THEN** the system shows a clear UI message, stops playback cleanly, and allows the user to retry initialization.

### Requirement: Data Forward Compatibility
The system SHALL support versioned data serialization.

#### Scenario: Missing Schema Version
- **WHEN** loading stored JSON data that lacks a `schemaVersion` field
- **THEN** the system defaults to reading it as version 1.

### Requirement: App Shutdown Cleanup
The system SHALL release hardware resources upon shutdown.

#### Scenario: App Closure
- **WHEN** the application is closed or terminated
- **THEN** the system cleanly disposes of the audio engine and releases all associated resources.
