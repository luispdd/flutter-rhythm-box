## ADDED Requirements

### Requirement: Metronome Header Tempo Indicator
The metronome screen SHALL display the active global tempo (in BPM) within the top application bar adjacent to the screen title and remove redundant tempo title text above the slider control.

#### Scenario: Header displays current BPM
- **WHEN** viewing the metronome screen
- **THEN** the top application bar displays the title "Metronome" and the current tempo value formatted with "BPM" (e.g., "120 BPM"), and no "Tempo: <N> BPM" label is rendered above the tempo slider.

#### Scenario: Tempo changes update header display
- **WHEN** the user increments, decrements, or slides the tempo control
- **THEN** the top application bar tempo text immediately updates to reflect the new BPM value.

### Requirement: Inline Compact Playback Control
The metronome screen SHALL provide an icon-only playback toggle positioned directly to the right of the active beat indicator sequence.

#### Scenario: Playback toggle icon states
- **WHEN** the metronome is idle
- **THEN** an icon-only play button is visible to the right of the beat numbers, displaying a play icon and no "Play" text.
- **WHEN** the metronome is playing
- **THEN** the icon updates to a stop icon and no "Stop" text.

#### Scenario: Toggle playback from inline button
- **WHEN** the user taps the inline icon button while idle
- **THEN** metronome playback begins and the beat circles animate in sync with audio output.
