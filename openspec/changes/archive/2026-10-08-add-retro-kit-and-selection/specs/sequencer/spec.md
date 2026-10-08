## ADDED Requirements

### Requirement: Sound kit selection
The system SHALL provide a kit selector in the top AppBar of the sequencer screen (positioned to the left of the pattern library button) allowing users to switch between available sound kits.

#### Scenario: Select sound kit in sequencer
- **WHEN** the user selects "Retro 8-bit" from the kit selector on the sequencer screen
- **THEN** the sequencer updates its active kit to "retro-8bit" and refreshes the track row labels accordingly

### Requirement: Dynamic track row labels
The step grid SHALL display voice labels matching the currently selected sound kit for tracks 0 through 7 (with track 7 at the top and track 0 at the bottom).

#### Scenario: Track labels reflect active kit
- **WHEN** the "retro-8bit" kit is selected
- **THEN** the grid displays "Kick" for track 0 and "Open hat" for track 7

### Requirement: Live kit swap at loop boundary
When the sequencer is playing and the user selects a different sound kit, the system SHALL synthesize the pattern with the newly selected kit and swap the loop buffer at the next loop boundary without audio interruption or timing glitches.

#### Scenario: Swap kit while playing
- **WHEN** the sequencer is playing with "classic-synth" and the user selects "retro-8bit"
- **THEN** playback continues uninterrupted and seamlessly transitions to the "retro-8bit" sound set at the start of the next loop cycle

### Requirement: Silent fallback for unknown kit
If a pattern specifies a `kitId` that is not available or registered in the kit repository, the sequencer SHALL silently fall back to `classic-synth`.

#### Scenario: Fallback on missing kit
- **WHEN** a pattern configured with an unknown kit ID is loaded into the sequencer
- **THEN** playback and editing use `classic-synth` without showing an error dialog or toast

## MODIFIED Requirements

### Requirement: Working Pattern Persistence
The system SHALL remember the user's current pattern edits and selected sound kit across application restarts.

#### Scenario: Restore Working Pattern
- **WHEN** the application starts
- **THEN** the sequencer restores the exact pattern grid, step count, and selected sound kit that was present when the application was last closed.
