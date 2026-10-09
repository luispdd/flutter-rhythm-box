# metronome Specification

## Purpose

Provides a standalone metronome interface allowing users to practice against a configurable synthesized click track.

## Requirements

### Requirement: Metronome Playback Control
The system SHALL provide an independent start and stop control for the metronome.

#### Scenario: Start Metronome
- **WHEN** the user presses play on the metronome screen
- **THEN** the audio engine begins looping the synthesized metronome track at the globally configured tempo and settings.

#### Scenario: Stop Metronome
- **WHEN** the user presses stop on the metronome screen
- **THEN** the metronome audio stops playing.

### Requirement: Global Tempo Synchronization
The metronome SHALL use the globally configured tempo (BPM).

#### Scenario: Change Tempo While Playing
- **WHEN** the metronome is playing and the global tempo is changed
- **THEN** the metronome re-renders the track for the new tempo and seamlessly swaps at the next loop boundary without audio gaps.

### Requirement: Metronome Audio Configuration
The system SHALL synthesize the metronome track based on configurable settings (Beats Per Bar, Waveform, Pitch, Decay, Accent).

#### Scenario: Change Settings
- **WHEN** the user modifies a metronome setting (e.g., changes beats per bar from 4 to 3)
- **THEN** the audio output updates to reflect the new configuration (swapping at the next loop boundary if currently playing).

### Requirement: Visual Beat Indicator
The system SHALL provide a visual approximation of the current beat.

#### Scenario: Display Beat
- **WHEN** the metronome is playing
- **THEN** the UI displays an indicator that synchronizes with the current audio playback position (UI-side approximation).

### Requirement: Persistence
The system SHALL remember the last used metronome settings and global tempo.

#### Scenario: Restore Settings
- **WHEN** the application starts
- **THEN** the previous metronome settings and global tempo are restored and applied.

### Requirement: Metronome Header Tempo Indicator
The metronome screen SHALL display the active global tempo (in BPM) within the top application bar adjacent to the screen title and remove redundant tempo title text above the slider control.

#### Scenario: Header displays current BPM
- **WHEN** viewing the metronome screen
- **THEN** the top application bar displays the title "Metronome" and the current tempo value formatted with "BPM" (e.g., "120 BPM"), and no "Tempo: <N> BPM" label is rendered above the tempo slider.

#### Scenario: Tempo changes update header display
- **WHEN** the user increments, decrements, or slides the tempo control
- **THEN** the top application bar tempo text immediately updates to reflect the new BPM value.

### Requirement: Inline Compact Playback Control
The metronome screen SHALL provide an icon-only playback toggle positioned directly to the right of the active beat indicator sequence.

#### Scenario: Playback toggle icon states
- **WHEN** the metronome is idle
- **THEN** an icon-only play button is visible to the right of the beat numbers, displaying a play icon and no "Play" text.
- **WHEN** the metronome is playing
- **THEN** the icon updates to a stop icon and no "Stop" text.

#### Scenario: Toggle playback from inline button
- **WHEN** the user taps the inline icon button while idle
- **THEN** metronome playback begins and the beat circles animate in sync with audio output.

