## Purpose

Defines data-driven sound kit structures, schema validation rules, bundled asset management, and the kit repository interface for Rhythm Box.

## ADDED Requirements

### Requirement: Sound kit data structure
A sound kit SHALL be represented as a data object with a schema version integer, unique stable string ID, display name, built-in flag, and a list of exactly 8 voices corresponding to tracks 0 (lowest) through 7 (highest).

#### Scenario: Sound kit serialization round-trip
- **WHEN** a valid sound kit is encoded to JSON and decoded back
- **THEN** all fields, including schema version, id, name, built-in flag, and all 8 voices, match the original object

### Requirement: Sound kit validation
The system SHALL strictly validate kit data on deserialization, requiring exactly 8 voices, valid waveform names, and in-range audio parameters (`startFreqHz`, `endFreqHz` >= 0; `decayMs` > 0; `gain` between 0.0 and 2.0; `dutyCycle` between 0.05 and 0.95; `bitDepth` between 2 and 16; `downsampleHz` >= 1000). Kits failing validation SHALL be rejected with descriptive error details and MUST NOT crash the application or be registered as available kits.

#### Scenario: Kit with incorrect voice count rejected
- **WHEN** a kit JSON containing 7 or 9 voices is validated
- **THEN** validation fails and the kit is not registered

#### Scenario: Out-of-range parameter rejected or caught
- **WHEN** a voice inside a kit specifies `dutyCycle = 1.2` or `bitDepth = 24`
- **THEN** validation rejects the kit with an explicit error

### Requirement: Built-in classic kit asset
The system SHALL bundle a built-in sound kit `assets/kits/classic-synth.json` with ID `classic-synth`, name "Classic synth", and builtIn set to `true`, containing the 8 parameter configurations matching the legacy voice ladder.

#### Scenario: Loading default built-in kit
- **WHEN** the application boots and initializes available kits
- **THEN** the `classic-synth` kit is successfully loaded from application assets and marked as built-in

### Requirement: Kit repository abstraction
A kit repository interface SHALL provide methods to retrieve all available kits, look up a kit by ID, and obtain the default kit (`classic-synth`). Missing or unrecognized kit lookups SHALL gracefully fall back to `classic-synth`.

#### Scenario: Lookup unknown kit falls back to default
- **WHEN** looking up a non-existent kit ID such as `"unknown-kit"`
- **THEN** the repository returns the `classic-synth` default kit without throwing an exception
