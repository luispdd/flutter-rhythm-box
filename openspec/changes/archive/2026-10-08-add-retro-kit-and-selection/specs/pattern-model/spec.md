## MODIFIED Requirements

### Requirement: Pattern structure
A pattern SHALL hold an id, a name, a tempo in BPM, a step count from 4 to 16 (default 16), an optional sound kit identifier `kitId` (defaulting to `'classic-synth'`), and 8 tracks of exactly 16 boolean steps each, where track 0 is the lowest voice.

#### Scenario: New empty pattern
- **WHEN** a new pattern is created
- **THEN** it has step count 16, tempo 120, kit ID 'classic-synth', and 8 tracks with all 16 steps off

#### Scenario: Step count out of range
- **WHEN** a step count below 4 or above 16 is requested
- **THEN** it is rejected or clamped to the nearest valid value, and the valid range is never exceeded

#### Scenario: Pattern with custom kit
- **WHEN** a pattern is created with `kitId = 'retro-8bit'`
- **THEN** its `kitId` property returns `'retro-8bit'`

### Requirement: Pattern JSON form
A pattern SHALL serialize to JSON with fields `id`, `name`, `tempoBpm`, `stepCount`, `kitId`, and `tracks` (8 arrays of 16 booleans), and SHALL deserialize back to an equal pattern. Missing `kitId` in older JSON payloads SHALL deserialize safely as `'classic-synth'`. Voices are not stored.

#### Scenario: Round trip
- **WHEN** a pattern is serialized and deserialized
- **THEN** the result equals the original, including `kitId`

#### Scenario: Backward compatibility with missing kitId
- **WHEN** a legacy pattern JSON without a `kitId` field is deserialized
- **THEN** the pattern successfully loads with `kitId` set to `'classic-synth'`

#### Scenario: Malformed track data
- **WHEN** JSON with fewer than 8 tracks or a track length other than 16 is deserialized
- **THEN** deserialization fails with a descriptive error
