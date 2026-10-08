# sequencer Specification

## Purpose

Provides a sequencer interface allowing users to compose, edit, and play an 8-track drum pattern.

## Requirements

### Requirement: Sequencer Playback Control
The system SHALL provide an independent start and stop control for the sequencer.

#### Scenario: Start Sequencer
- **WHEN** the user presses play on the sequencer screen
- **THEN** the audio engine begins looping the synthesized pattern at the globally configured tempo.

#### Scenario: Stop Sequencer
- **WHEN** the user presses stop on the sequencer screen
- **THEN** the sequencer audio stops playing.

### Requirement: Interactive Step Grid
The system SHALL provide an 8-track by up to 16-step grid where users can toggle individual steps.

#### Scenario: Toggle Step
- **WHEN** the user taps an inactive step cell in the grid
- **THEN** that step becomes active and will trigger a drum hit during playback.

#### Scenario: Edit While Playing
- **WHEN** the sequencer is playing and the user toggles a step
- **THEN** the audio track is seamlessly updated at the next loop boundary to include the new step without stopping playback.

### Requirement: Adjustable Step Count
The system SHALL allow the user to adjust the active step count of the loop between 4 and 16.

#### Scenario: Reduce Step Count
- **WHEN** the user reduces the step count from 16 to 8
- **THEN** the sequencer loops only the first 8 steps, but previously entered steps in positions 9-16 are preserved in memory.

### Requirement: Clear Pattern
The system SHALL provide a way to clear all steps in the current pattern.

#### Scenario: Clear All Steps
- **WHEN** the user triggers the clear action
- **THEN** all steps across all 8 tracks are reset to inactive.

### Requirement: Working Pattern Persistence
The system SHALL remember the user's current pattern edits across application restarts.

#### Scenario: Restore Working Pattern
- **WHEN** the application starts
- **THEN** the sequencer restores the exact pattern grid and step count that was present when the application was last closed.

### Requirement: Improved UX and Controls (Added post-integration)
The system SHALL provide enhanced visual and interactive controls for the sequencer and shared components.

#### Scenario: Playhead Visualization
- **WHEN** the sequencer is playing
- **THEN** the current active step is indicated by a horizontal rectangular bullet displayed above the respective column, without altering the step cell background colors.

#### Scenario: Step Count Slider
- **WHEN** adjusting the sequence length
- **THEN** the step count is adjusted via a slider control rather than a dropdown menu.

#### Scenario: Track Identifiers
- **WHEN** viewing the step grid
- **THEN** each track row has a visible identifier (e.g., "Trk 1") displayed on the left side.

#### Scenario: Long-Press Value Adjustment
- **WHEN** the user long-presses the `+` or `-` buttons next to the tempo slider (or other future controls)
- **THEN** the underlying value continuously increments or decrements at a constant pace for the duration of the press.

#### Scenario: Mutually Exclusive Playback
- **WHEN** the user starts the sequencer while the metronome is already playing
- **THEN** the metronome stops automatically to prevent overlapping audio loops, and vice-versa.
