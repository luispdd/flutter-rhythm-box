## Purpose

Defines the sequencer's pattern data: 8 tracks of 16 stored steps with an adjustable active step count, plus its JSON form, so patterns can be edited, rendered and later saved without loss.

## ADDED Requirements

### Requirement: Pattern structure
A pattern SHALL hold an id, a name, a tempo in BPM, a step count from 4 to 16 (default 16), and 8 tracks of exactly 16 boolean steps each, where track 0 is the lowest voice.

#### Scenario: New empty pattern
- **WHEN** a new pattern is created
- **THEN** it has step count 16, tempo 120, and 8 tracks with all 16 steps off

#### Scenario: Step count out of range
- **WHEN** a step count below 4 or above 16 is requested
- **THEN** it is rejected or clamped to the nearest valid value, and the valid range is never exceeded

### Requirement: Steps survive step-count changes
Reducing and then increasing the step count SHALL preserve previously entered steps, because all 16 steps per track are always stored and only the first `stepCount` are used.

#### Scenario: Shrink then grow
- **WHEN** step 14 of track 2 is on, the step count is set to 8, and then set back to 16
- **THEN** step 14 of track 2 is still on

#### Scenario: Hidden steps are not played
- **WHEN** the step count is 8 and step 12 of a track is on
- **THEN** the rendered loop contains only the first 8 steps and no hit for step 12

### Requirement: Editing returns a new pattern value
Toggling a step or clearing the pattern SHALL not mutate the original pattern instance.

#### Scenario: Toggle step
- **WHEN** a step is toggled on a pattern
- **THEN** the returned pattern has that step flipped and the original is unchanged

#### Scenario: Clear pattern
- **WHEN** the clear action is applied
- **THEN** all 8x16 steps are off, and the name, tempo and step count are unchanged

### Requirement: Pattern JSON form
A pattern SHALL serialize to JSON with fields `id`, `name`, `tempoBpm`, `stepCount` and `tracks` (8 arrays of 16 booleans), and SHALL deserialize back to an equal pattern. Voices are not stored.

#### Scenario: Round trip
- **WHEN** a pattern is serialized and deserialized
- **THEN** the result equals the original

#### Scenario: Malformed track data
- **WHEN** JSON with fewer than 8 tracks or a track length other than 16 is deserialized
- **THEN** deserialization fails with a descriptive error
