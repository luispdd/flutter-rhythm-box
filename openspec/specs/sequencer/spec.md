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
The system SHALL remember the user's current pattern edits and selected sound kit across application restarts.

#### Scenario: Restore Working Pattern
- **WHEN** the application starts
- **THEN** the sequencer restores the exact pattern grid, step count, and selected sound kit that was present when the application was last closed.

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

### Requirement: Sequencer Header Tempo Indicator
The sequencer screen SHALL display the active global tempo (in BPM) within the top application bar adjacent to the screen title and remove redundant tempo title text above the slider control.

#### Scenario: Header displays current BPM
- **WHEN** viewing the sequencer screen
- **THEN** the top application bar displays "Sequencer" and the current tempo value formatted with "BPM" (e.g., "120 BPM"), and no "Tempo: <N> BPM" label is rendered above the tempo slider.

#### Scenario: Title truncation protection
- **WHEN** the top bar contains the title, BPM indicator, sound kit dropdown, and pattern library icon on constrained screen widths
- **THEN** the title text truncates or shrinks gracefully without causing RenderFlex overflow errors.

### Requirement: Streamlined Sequencer Control Strip
The sequencer controls row SHALL order interactive elements from left to right as: track label toggle, step count selector, clear pattern action, save pattern action, and playback toggle.

#### Scenario: Icon-only actions in control row
- **WHEN** viewing the sequencer controls row
- **THEN** the clear pattern action is an icon button without the text "Clear", the save pattern action is an icon button without the text "Save", and the play/stop toggle is an icon button located on the far right without textual state labels.

### Requirement: Collapsible Track Labels
The sequencer SHALL provide a toggle button to show or hide track labels, dynamically maximizing horizontal space for the step grid.

#### Scenario: Default visibility based on target platform
- **WHEN** the application starts on a mobile device (Android or iOS)
- **THEN** track labels in the sequencer step grid and playhead ruler are hidden by default.
- **WHEN** the application starts on desktop (Linux)
- **THEN** track labels are visible by default.

#### Scenario: Toggling track label visibility
- **WHEN** the user taps the track label toggle button in the control strip
- **THEN** track label visibility toggles between visible and hidden for the current session, and both the playhead ruler and step grid adjust horizontal margins so step indicators remain vertically aligned with their grid columns.

### Requirement: Sequencer Viewport Scrollability
The sequencer screen SHALL support vertical scrolling with fixed-height track rows to ensure all controls and step selectors are accessible regardless of device orientation.

#### Scenario: Viewing sequencer in horizontal landscape orientation
- **WHEN** the device is oriented horizontally with reduced vertical viewport height
- **THEN** the sequencer screen is scrollable vertically, and users can scroll down to inspect and toggle all 8 track rows and steps without UI truncation or RenderFlex overflow errors.

