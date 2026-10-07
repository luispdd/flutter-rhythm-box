# Shared Tempo Specification

## Purpose

Defines the single global tempo that the metronome and the sequencer both follow, including its valid range and how a change reaches playback.

## Requirements

### Requirement: Global tempo value
The system SHALL hold one tempo in whole beats per minute, from 30 to 300, with a default of 120, shared by the metronome and the sequencer.

#### Scenario: Default
- **WHEN** the app starts with no stored tempo
- **THEN** the tempo is 120 BPM

#### Scenario: Out-of-range values are clamped
- **WHEN** a tempo below 30 or above 300 is set
- **THEN** the tempo becomes 30 or 300 respectively

#### Scenario: Increment and decrement
- **WHEN** the tempo is 300 and it is incremented, or 30 and it is decremented
- **THEN** it stays at the bound

### Requirement: One value for both sources
Changing the tempo SHALL change it for both the metronome and the sequencer.

#### Scenario: Shared change
- **WHEN** the tempo is set to 90 while the metronome screen is shown
- **THEN** the sequencer's rendered loop uses 90 BPM the next time it renders

### Requirement: Tempo change while playing
A tempo change during playback SHALL cause a re-render and be applied only at the next loop boundary.

#### Scenario: Change mid-loop
- **WHEN** the tempo changes while a loop is playing
- **THEN** the playing loop finishes unchanged and the new tempo starts at the next boundary
