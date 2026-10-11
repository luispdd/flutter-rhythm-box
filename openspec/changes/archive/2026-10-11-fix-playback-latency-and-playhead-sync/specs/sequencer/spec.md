## MODIFIED Requirements

### Requirement: Interactive Step Grid
The system SHALL provide an 8-track by up to 16-step grid where users can toggle individual steps.

#### Scenario: Toggle Step
- **WHEN** the user taps an inactive step cell in the grid
- **THEN** that step becomes active and will trigger a drum hit during playback.

#### Scenario: Edit While Playing
- **WHEN** the sequencer is playing and the user toggles a step
- **THEN** the audio track is seamlessly updated at the immediate next loop boundary to include the new step without stopping playback
- **AND** pattern persistence to storage is processed without delaying the audio swap schedule or pushing the swap into a later cycle.

#### Scenario: Step Playhead Stability During Live Edits
- **WHEN** the user toggles any step while playback is active
- **THEN** the visual playhead continues advancing steadily through each step column without resetting to step 0, lagging, or desynchronizing for 1 or 2 loops.
