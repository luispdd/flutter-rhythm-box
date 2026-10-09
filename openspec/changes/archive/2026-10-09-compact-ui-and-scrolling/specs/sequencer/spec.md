## ADDED Requirements

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
