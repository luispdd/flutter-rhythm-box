# Metronome Settings Specification

## Purpose

Defines the metronome's adjustable settings and their JSON form, so M2 can build the screen and storage on a validated model.

## Requirements

### Requirement: Metronome settings values
Metronome settings SHALL hold beats per bar (2 to 9, default 4), accent on beat 1 (default on), waveform (sine, triangle or square), pitch in Hz (200 to 4000, default 1000), and decay in ms (10 to 200, default 40). The accent pitch SHALL be 1.5 times the pitch.

#### Scenario: Defaults
- **WHEN** default settings are created
- **THEN** beats per bar is 4, the accent is on, the pitch is 1000 Hz, the decay is 40 ms, and the accent pitch is 1500 Hz

#### Scenario: Values clamped to range
- **WHEN** a pitch of 50 Hz, a decay of 500 ms, or 12 beats per bar is set
- **THEN** the value becomes 200 Hz, 200 ms, or 9 respectively

#### Scenario: Noise is not a click waveform
- **WHEN** the waveform noise is requested for the metronome
- **THEN** it is rejected

### Requirement: Settings JSON form
Metronome settings SHALL serialize to JSON and deserialize to equal settings, and missing fields in stored JSON SHALL fall back to the defaults.

#### Scenario: Round trip
- **WHEN** settings are serialized and deserialized
- **THEN** the result equals the original

#### Scenario: Partial JSON
- **WHEN** JSON with only the pitch present is deserialized
- **THEN** all other fields take their default values
