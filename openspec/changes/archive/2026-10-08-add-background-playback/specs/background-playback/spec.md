## Purpose

Enables the application to continue playing audio without interruption when the Android device's screen is turned off or the app is sent to the background.

## ADDED Requirements

### Requirement: Background Audio Playback
The system SHALL keep the audio engine running while the app is in the background.

#### Scenario: Screen Turned Off
- **WHEN** the user is playing the metronome, pattern sequencer, or a sequence, and the device screen is turned off
- **THEN** the audio playback continues uninterrupted.

### Requirement: Persistent Notification Control
The system SHALL provide a notification to control playback in the background.

#### Scenario: Stop from Notification
- **WHEN** the app is playing audio in the background
- **THEN** a persistent MediaStyle notification is displayed with a "Stop" button.

#### Scenario: Clean Shutdown from Notification
- **WHEN** the user taps the "Stop" button in the notification
- **THEN** the audio playback stops, the background service terminates, and the notification is removed.
