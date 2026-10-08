## ADDED Requirements

### Requirement: Built-in retro kit asset
The system SHALL bundle a built-in sound kit `assets/kits/retro-8bit.json` with ID `retro-8bit`, name "Retro 8-bit", and builtIn set to `true`, containing exactly 8 chiptune voice configurations for tracks 0 through 7 matching the specification.

#### Scenario: Loading retro built-in kit
- **WHEN** the kit repository initializes
- **THEN** both `classic-synth` and `retro-8bit` kits are loaded and marked as built-in

### Requirement: Multiple kit discovery
The kit repository SHALL expose all loaded built-in kits through `availableKits`, allowing consumers to list them and look them up by ID.

#### Scenario: Discover available kits
- **WHEN** querying available kits from the repository
- **THEN** both `classic-synth` and `retro-8bit` kits are returned in the list
